# Anleitung: Google Apps Script Backend einrichten

Dieses Backend stellt über `doGet` und `doPost` alle Daten für die Flutter-App bereit und führt Berechnungen (Google Maps Distanzen & Monatsabrechnungen) direkt in der Google Cloud aus.

---

## 1. Google Tabelle erstellen
1. Öffne [Google Drive](https://drive.google.com/) und erstelle eine neue Google Tabelle (Google Sheets).
2. Benenne die Tabelle z. B. **"Mitfahrgelegenheiten_Datenbank"**.

---

## 2. Apps Script Code einfügen
1. Klicke im Menü der Google Tabelle auf **Erweiterungen** -> **Apps Script**.
2. Ersetze den Inhalt von `Code.gs` durch den Code aus der Datei [`backend/Code.gs`](Code.gs).
3. Speichere das Projekt mit dem Diskette-Symbol (oder `Strg + S`).

---

## 3. (Optional) Beispieldaten erzeugen
1. Wähle oben in der Funktionsleiste die Funktion `seedSampleData` aus.
2. Klicke auf **Ausführen** (Run).
3. Bei der ersten Ausführung fordert Google Berechtigungen an:
   - Klicke auf **Berechtigungen prüfen** -> Wähle dein Google-Konto -> **Erweitert** -> **Öffnen (unsicher)** -> **Zulassen**.
4. In deiner Google Tabelle werden jetzt automatisch die vier Blätter angelegt:
   - `Teilnehmer` (inkl. Muster-Wohnadressen)
   - `Ziele` (Firmenstandorte)
   - `Fahrten`
   - `Abrechnungen`

---

## 4. Als Web-App bereitstellen
1. Klicke oben rechts auf den blauen Button **Bereitstellen** (Deploy) -> **Neue Bereitstellung**.
2. Wähle als Typ (Zahnrad-Symbol) **Web-App** aus.
3. Konfiguriere folgende Einstellungen:
   - **Beschreibung:** z. B. `Version 1`
   - **Ausführen als:** `Ich (deine E-Mail)`
   - **Wer hat Zugriff:** `Jeder` *(Wichtig: Damit die Flutter Web App ohne OAuth-Login per doGet/doPost kommunizieren kann)*
4. Klicke auf **Bereitstellen**.
5. Kopiere die angezeigte **Web-App-URL** (beginnt mit `https://script.google.com/macros/s/.../exec`).

---

## 5. URL in die Flutter Web App einfügen
- Öffne die Flutter App (oder die Vorschau).
- Gehe auf **Einstellungen** (Zahnrad-Symbol).
- Trage deine kopierte Web-App-URL ein und deaktiviere den Demo-Modus.
- Klicke auf **Verbindung testen** – die App lädt nun direkt deine Live-Daten aus Google Sheets!
