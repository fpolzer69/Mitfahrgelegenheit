@echo off
echo =========================================================================
echo Visual Studio C++ Compiler fuer Flutter Windows Desktop Installation
echo =========================================================================
echo.
echo Der Installer fuer den Microsoft C++ Compiler wird jetzt gestartet...
echo Bitte bestaetigen Sie die Windows-Abfrage (Benutzerkontensteuerung / UAC) mit "Ja".
echo.
"%~dp0vs_BuildTools.exe" --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended
echo.
echo Installation abgeschlossen oder laeuft im Hintergrund.
pause
