/**
 * Google Apps Script Backend für Mitfahrgelegenheiten-Verwaltung
 * 
 * Funktionen:
 * - doGet(e): Abruf von Teilnehmern, Zielen, Fahrten, Abrechnung und Google Maps Distanz
 * - doPost(e): Erstellen/Aktualisieren/Löschen von Einträgen und Generieren der Monatsabrechnung
 * - Automatische Initialisierung der Tabellenblätter bei Bedarf
 */

const SHEET_NAMES = {
  PARTICIPANTS: 'Teilnehmer',
  DESTINATIONS: 'Ziele',
  RIDES: 'Fahrten',
  BILLING: 'Abrechnungen'
};

const DEFAULT_KM_RATE = 0.30; // Euro pro Kilometer

/**
 * HTTP GET Handler
 */
function doGet(e) {
  try {
    const params = e ? e.parameter : {};
    const action = params.action || 'ping';

    let result;
    switch (action) {
      case 'ping':
        result = { status: 'ok', serverTime: new Date().toISOString(), message: 'Mitfahrgelegenheiten API online' };
        break;

      case 'getParticipants':
        result = getSheetData(SHEET_NAMES.PARTICIPANTS);
        break;

      case 'getDestinations':
        result = getSheetData(SHEET_NAMES.DESTINATIONS);
        break;

      case 'getRides':
        const monthFilter = params.month; // z.B. "2026-10"
        let rides = getSheetData(SHEET_NAMES.RIDES);
        if (monthFilter) {
          rides = rides.filter(r => (r.datum || '').startsWith(monthFilter));
        }
        result = rides;
        break;

      case 'getBilling':
        const billingMonth = params.month;
        let billing = getSheetData(SHEET_NAMES.BILLING);
        if (billingMonth) {
          billing = billing.filter(b => b.zeitraum === billingMonth);
        }
        result = billing;
        break;

      case 'calculateDistance':
        const origin = params.origin;
        const destination = params.destination;
        if (!origin || !destination) {
          throw new Error('Parameter "origin" und "destination" sind erforderlich.');
        }
        result = calculateDistanceWithGoogleMaps(origin, destination);
        break;

      default:
        throw new Error('Unbekannte Aktion: ' + action);
    }

    return createJsonResponse({ success: true, data: result });
  } catch (error) {
    return createJsonResponse({ success: false, error: error.message });
  }
}

/**
 * HTTP POST Handler
 */
function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      throw new Error('Kein Anfrage-Body vorhanden.');
    }

    let payload;
    try {
      payload = JSON.parse(e.postData.contents);
    } catch (parseError) {
      throw new Error('Ungültiges JSON im Anfrage-Body: ' + parseError.message);
    }

    const action = payload.action;
    const data = payload.data || {};
    let result;

    switch (action) {
      case 'saveParticipant':
        result = upsertRow(SHEET_NAMES.PARTICIPANTS, data, 'id', 'T-');
        break;

      case 'deleteParticipant':
        result = deleteRow(SHEET_NAMES.PARTICIPANTS, data.id);
        break;

      case 'saveDestination':
        result = upsertRow(SHEET_NAMES.DESTINATIONS, data, 'id', 'Z-');
        break;

      case 'deleteDestination':
        result = deleteRow(SHEET_NAMES.DESTINATIONS, data.id);
        break;

      case 'saveRide':
        // Falls keine Distanz angegeben, automatisch berechnen
        if (!data.distanz_km && data.fahrer_id && data.ziel_id) {
          data.distanz_km = autoCalculateRideDistance(data.fahrer_id, data.ziel_id);
        }
        result = upsertRow(SHEET_NAMES.RIDES, data, 'id', 'F-');
        break;

      case 'deleteRide':
        result = deleteRow(SHEET_NAMES.RIDES, data.id);
        break;

      case 'generateMonthlyBilling':
        result = executeMonthlyBilling(data.month, data.kmRate || DEFAULT_KM_RATE);
        break;

      default:
        throw new Error('Unbekannte POST-Aktion: ' + action);
    }

    return createJsonResponse({ success: true, data: result });
  } catch (error) {
    return createJsonResponse({ success: false, error: error.message });
  }
}

/**
 * Google Maps Entfernungsberechnung via native Apps Script Maps API
 */
function calculateDistanceWithGoogleMaps(origin, destination) {
  try {
    const directions = Maps.newDirectionFinder()
      .setOrigin(origin)
      .setDestination(destination)
      .setMode(Maps.DirectionFinder.Mode.DRIVING)
      .setLanguage('de')
      .getDirections();

    if (!directions || directions.status !== 'OK' || !directions.routes || directions.routes.length === 0) {
      return {
        status: directions ? directions.status : 'NO_ROUTE',
        origin: origin,
        destination: destination,
        distanceKm: 0,
        durationMinutes: 0,
        durationText: 'Nicht ermittelbar',
        error: 'Keine Route gefunden oder Adresse ungenau.'
      };
    }

    const leg = directions.routes[0].legs[0];
    const distanceMeters = leg.distance.value;
    const distanceKm = Math.round((distanceMeters / 1000) * 10) / 10;
    const durationMinutes = Math.round(leg.duration.value / 60);

    return {
      status: 'OK',
      origin: leg.start_address || origin,
      destination: leg.end_address || destination,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      durationText: leg.duration.text
    };
  } catch (err) {
    return {
      status: 'ERROR',
      origin: origin,
      destination: destination,
      distanceKm: 0,
      durationMinutes: 0,
      error: err.message
    };
  }
}

/**
 * Hilfsfunktion: Berechnet Distanz zwischen Fahreradresse und Ziel
 */
function autoCalculateRideDistance(fahrerId, zielId) {
  const participants = getSheetData(SHEET_NAMES.PARTICIPANTS);
  const destinations = getSheetData(SHEET_NAMES.DESTINATIONS);

  const driver = participants.find(p => p.id === fahrerId);
  const target = destinations.find(d => d.id === zielId);

  if (driver && target && driver.adresse && target.adresse) {
    const distInfo = calculateDistanceWithGoogleMaps(driver.adresse, target.adresse);
    return distInfo.distanceKm || 0;
  }
  return 0;
}

/**
 * Monatsabrechnung ausführen und in Tabelle "Abrechnungen" speichern
 */
function executeMonthlyBilling(monthStr, kmRate) {
  if (!monthStr || !monthStr.match(/^\d{4}-\d{2}$/)) {
    throw new Error('Ungültiger Abrechnungsmonat. Format muss YYYY-MM sein (z.B. 2026-10).');
  }

  const participants = getSheetData(SHEET_NAMES.PARTICIPANTS);
  const rides = getSheetData(SHEET_NAMES.RIDES).filter(r => (r.datum || '').startsWith(monthStr));

  const participantMap = {};
  participants.forEach(p => {
    participantMap[p.id] = {
      id: 'ABR-' + monthStr + '-' + p.id,
      zeitraum: monthStr,
      teilnehmer_id: p.id,
      teilnehmer_name: (p.vorname + ' ' + p.nachname).trim(),
      fahrten_fahrer: 0,
      fahrten_mitfahrer: 0,
      km_fahrer: 0,
      km_mitfahrer: 0,
      betrag_gutschrift: 0,
      betrag_lastschrift: 0,
      saldo: 0,
      status: 'Berechnet'
    };
  });

  // Jede Fahrt auswerten
  rides.forEach(ride => {
    let km = parseFloat(ride.distanz_km) || 0;
    // Falls Hin- und Rückfahrt ausgewählt ist, verdoppeln
    if ((ride.richtung || '').toLowerCase().indexOf('rück') !== -1 && (ride.richtung || '').toLowerCase().indexOf('hin') !== -1) {
      km = km * 2;
    }

    const driverId = (ride.fahrer_id || '').trim();
    const rawPassengers = (ride.mitfahrer_ids || '').split(',');
    const passengerIds = rawPassengers.map(s => s.trim()).filter(s => s.length > 0 && s !== driverId);

    const passengerCount = passengerIds.length;
    const totalOccupants = 1 + passengerCount; // Fahrer + Mitfahrer

    const totalRideCost = km * kmRate;
    const costPerPerson = totalRideCost / totalOccupants;

    // Gutschrift für den Fahrer: Jeder Mitfahrer zahlt seinen Anteil an den Fahrer
    const driverCredit = costPerPerson * passengerCount;

    if (driverId && participantMap[driverId]) {
      const d = participantMap[driverId];
      d.fahrten_fahrer += 1;
      d.km_fahrer += km;
      d.betrag_gutschrift += driverCredit;
    }

    // Lastschrift für jeden Mitfahrer
    passengerIds.forEach(pId => {
      if (participantMap[pId]) {
        const p = participantMap[pId];
        p.fahrten_mitfahrer += 1;
        p.km_mitfahrer += (km / totalOccupants);
        p.betrag_lastschrift += costPerPerson;
      }
    });
  });

  // Saldo berechnen und runden
  const billingList = [];
  Object.keys(participantMap).forEach(key => {
    const item = participantMap[key];
    item.km_fahrer = Math.round(item.km_fahrer * 10) / 10;
    item.km_mitfahrer = Math.round(item.km_mitfahrer * 10) / 10;
    item.betrag_gutschrift = Math.round(item.betrag_gutschrift * 100) / 100;
    item.betrag_lastschrift = Math.round(item.betrag_lastschrift * 100) / 100;
    item.saldo = Math.round((item.betrag_gutschrift - item.betrag_lastschrift) * 100) / 100;

    // Nur Teilnehmer aufnehmen, die in diesem Monat beteiligt waren
    if (item.fahrten_fahrer > 0 || item.fahrten_mitfahrer > 0) {
      billingList.push(item);
      upsertRow(SHEET_NAMES.BILLING, item, 'id', 'ABR-');
    }
  });

  return {
    month: monthStr,
    kmRate: kmRate,
    rideCount: rides.length,
    participantsBilled: billingList.length,
    billingList: billingList
  };
}

/**
 * Liest alle Daten aus einem Tabellenblatt als JSON-Array von Objekten
 */
function getSheetData(sheetName) {
  ensureSheetHeaders(sheetName);
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0].map(h => String(h).trim().toLowerCase());
  const rows = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    // Leere Zeilen überspringen
    if (row.every(cell => cell === '' || cell === null)) continue;

    const obj = {};
    headers.forEach((header, colIndex) => {
      let val = row[colIndex];
      if (val instanceof Date) {
        val = Utilities.formatDate(val, Session.getScriptTimeZone(), 'yyyy-MM-dd');
      }
      obj[header] = val;
    });
    rows.push(obj);
  }

  return rows;
}

/**
 * Zeile hinzufügen oder aktualisieren (Upsert)
 */
function upsertRow(sheetName, item, idKey, idPrefix) {
  ensureSheetHeaders(sheetName);
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(sheetName);

  const data = sheet.getDataRange().getValues();
  const headers = data[0].map(h => String(h).trim().toLowerCase());
  const idColIdx = headers.indexOf(idKey.toLowerCase());

  if (idColIdx === -1) {
    throw new Error('ID-Spalte "' + idKey + '" in Tabelle "' + sheetName + '" nicht gefunden.');
  }

  // Falls keine ID vorhanden ist, neue erzeugen
  if (!item[idKey]) {
    item[idKey] = (idPrefix || 'ID-') + (new Date().getTime().toString().slice(-6));
  }

  const itemIdStr = String(item[idKey]).trim();
  let foundRowIndex = -1;

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idColIdx]).trim() === itemIdStr) {
      foundRowIndex = i + 1; // 1-basiert
      break;
    }
  }

  const rowValues = headers.map(h => {
    return item[h] !== undefined ? item[h] : '';
  });

  if (foundRowIndex > 0) {
    sheet.getRange(foundRowIndex, 1, 1, headers.length).setValues([rowValues]);
    return { action: 'updated', item: item };
  } else {
    sheet.appendRow(rowValues);
    return { action: 'created', item: item };
  }
}

/**
 * Zeile anhand der ID löschen
 */
function deleteRow(sheetName, idVal) {
  ensureSheetHeaders(sheetName);
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(sheetName);

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return { deleted: false };

  const headers = data[0].map(h => String(h).trim().toLowerCase());
  const idColIdx = headers.indexOf('id');

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][idColIdx]).trim() === String(idVal).trim()) {
      sheet.deleteRow(i + 1);
      return { deleted: true, id: idVal };
    }
  }

  return { deleted: false, message: 'Eintrag nicht gefunden' };
}

/**
 * Stellt sicher, dass das Blatt und die Standard-Kopfzeilen existieren
 */
function ensureSheetHeaders(sheetName) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
  }

  if (sheet.getLastRow() === 0) {
    let headers = [];
    switch (sheetName) {
      case SHEET_NAMES.PARTICIPANTS:
        headers = ['id', 'vorname', 'nachname', 'adresse', 'email', 'telefon', 'rolle', 'aktiv'];
        break;
      case SHEET_NAMES.DESTINATIONS:
        headers = ['id', 'name', 'adresse', 'kontakt', 'notizen'];
        break;
      case SHEET_NAMES.RIDES:
        headers = ['id', 'datum', 'fahrer_id', 'mitfahrer_ids', 'ziel_id', 'distanz_km', 'richtung', 'bemerkung'];
        break;
      case SHEET_NAMES.BILLING:
        headers = ['id', 'zeitraum', 'teilnehmer_id', 'teilnehmer_name', 'fahrten_fahrer', 'fahrten_mitfahrer', 'km_fahrer', 'km_mitfahrer', 'betrag_gutschrift', 'betrag_lastschrift', 'saldo', 'status'];
        break;
    }
    if (headers.length > 0) {
      const headerRange = sheet.getRange(1, 1, 1, headers.length);
      headerRange.setValues([headers]);
      headerRange.setFontWeight('bold');
      headerRange.setBackground('#F3F4F6');
      sheet.setFrozenRows(1);
    }
  }
}

/**
 * Hilfsfunktion zur Erzeugung einer JSON-HTTP-Antwort mit CORS-Unterstützung
 */
function createJsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

/**
 * Einmalige Testdaten-Initialisierung (kann direkt im Apps Script Editor ausgeführt werden)
 */
function seedSampleData() {
  ensureSheetHeaders(SHEET_NAMES.PARTICIPANTS);
  ensureSheetHeaders(SHEET_NAMES.DESTINATIONS);
  ensureSheetHeaders(SHEET_NAMES.RIDES);
  ensureSheetHeaders(SHEET_NAMES.BILLING);

  const sampleParticipants = [
    { id: 'T-1001', vorname: 'Max', nachname: 'Mustermann', adresse: 'Kaiserstraße 45, 60329 Frankfurt am Main', email: 'max@example.com', telefon: '+49 170 1234567', rolle: 'Fahrer', aktiv: true },
    { id: 'T-1002', vorname: 'Anna', nachname: 'Schmidt', adresse: 'Bockenheimer Warte 3, 60325 Frankfurt am Main', email: 'anna@example.com', telefon: '+49 171 2345678', rolle: 'Mitfahrer', aktiv: true },
    { id: 'T-1003', vorname: 'Lukas', nachname: 'Weber', adresse: 'Schweizer Straße 18, 60594 Frankfurt am Main', email: 'lukas@example.com', telefon: '+49 172 3456789', rolle: 'Flexibel', aktiv: true },
    { id: 'T-1004', vorname: 'Laura', nachname: 'Fischer', adresse: 'Eckenheimer Landstr. 100, 60318 Frankfurt am Main', email: 'laura@example.com', telefon: '+49 173 4567890', rolle: 'Mitfahrer', aktiv: true }
  ];

  sampleParticipants.forEach(p => upsertRow(SHEET_NAMES.PARTICIPANTS, p, 'id', 'T-'));

  const sampleDestinations = [
    { id: 'Z-2001', name: 'Industriepark Höchst - Tor Ost', adresse: 'Brüningstraße 50, 65929 Frankfurt am Main', kontakt: 'Pforte Tor Ost', notizen: 'Besucherausweis vorzeigen' },
    { id: 'Z-2002', name: 'Flughafen CargoCity Süd', adresse: 'Gebäude 532, 60549 Frankfurt am Main', kontakt: 'Logistikzentrum', notizen: 'Parkausweis P3' }
  ];

  sampleDestinations.forEach(d => upsertRow(SHEET_NAMES.DESTINATIONS, d, 'id', 'Z-'));

  Logger.log('Beispieldaten erfolgreich in Google Sheets angelegt.');
}
