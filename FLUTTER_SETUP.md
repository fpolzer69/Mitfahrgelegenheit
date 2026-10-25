# Anleitung: Flutter unter Windows einrichten und ausführen

Da das Flutter SDK auf diesem System aktuell noch nicht in den Umgebungsvariablen (`PATH`) hinterlegt ist, finden Sie hier die Schritte zur Installation und zum Start der Web-App.

---

## 1. Flutter SDK herunterladen & installieren

1. Laden Sie das offizielle Flutter Windows SDK herunter:
   - [Flutter Windows SDK Download](https://docs.flutter.dev/get-started/install/windows/web)
2. Entpacken Sie die ZIP-Datei an einen festen Ort, z. B.:
   `C:\src\flutter` oder `C:\flutter`
   *(Hinweis: Nicht in `C:\Program Files` entpacken, um Berechtigungskonflikte zu vermeiden).*

---

## 2. Flutter zur Umgebungsvariable `PATH` hinzufügen

1. Drücken Sie die Windows-Taste und tippen Sie `Umgebungsvariablen`.
2. Wählen Sie **"Umgebungsvariablen für dieses Konto bearbeiten"**.
3. Wählen Sie unter *Benutzervariablen* den Eintrag **Path** aus und klicken Sie auf **Bearbeiten**.
4. Klicken Sie auf **Neu** und tragen Sie den Pfad zum `bin`-Ordner ein, z. B.:
   `C:\src\flutter\bin`
5. Bestätigen Sie alle Dialoge mit **OK**.
6. Öffnen Sie ein neues Terminalfenster und prüfen Sie die Installation:
   ```powershell
   flutter --version
   flutter doctor
   ```

---

## 3. Web-Unterstützung aktivieren & App starten

Wechseln Sie in das Projektverzeichnis `c:\Mitfahrgelegenheit` und führen Sie folgende Befehle aus:

```powershell
cd c:\Mitfahrgelegenheit

# Abhängigkeiten herunterladen
flutter pub get

# Web-App direkt im Google Chrome starten
flutter run -d chrome
```

Die Flutter-App öffnet sich automatisch in Google Chrome und verbindet sich im Demo-Modus mit den Testdaten. Unter **Einstellungen** können Sie jederzeit Ihre Google Apps Script URL hinterlegen.
