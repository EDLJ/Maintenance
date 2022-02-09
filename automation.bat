@echo off

:: Elevate Privileges
set "params=%*"
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )


:: Create Restore Point
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command "Checkpoint-Computer -Description "MaintenanceVisit" -RestorePointType "MODIFY_SETTINGS"; " ' " -Verb RunAs}"


:: Create Folder on Current Desktop for Exported Logs
mkdir "%userprofile%\Desktop\MCA-Logs"


:: Generate and Export System Information
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"OS Manufacturer" /C:"OS Configuration" /C:"OS Build Type" /C:"Original Install Date" /C:"System Boot Time" /C:"System Manufacturer" /C:"System Model" /C:"System Type" /C:"Processor(s)" /C:"BIOS Version" /C:"Windows Directory" /C:"System Directory" /C:"Boot Device" /C:"System Locale" /C:"Input Locale" /C:"Total Physical Memory" /C:"Available Physical Memory" /C:"Virtual Memory: Max Size" /C:"Virtual Memory: Available" /C:"Virtual Memory: In Use" /C:"Domain" /C:"Network Card(s)" > "%userprofile%\Desktop\MCA-Logs\SystemInfo.txt"
echo System Info successfully loaded and exported.
pause


:: Export IPCONFIG
ipconfig /all > "%userprofile%\Desktop\MCA-Logs\IPCONFIG.txt"


:: Install CrystalDiskInfo silently off USB 
"%~dp0\crystalDiskInstaller.exe" /VERYSILENT /NORESTART /MERGETASKS=!desktopicon64 /LOG="%userprofile%\Desktop\MCA-Logs\CrystalDiskInfo-Install.log"


:: Run CrystalDiskInfo & Export Logs
"%ProgramFiles%\CrystalDiskInfo\DiskInfo64.exe" /CopyExit
move /y "%ProgramFiles%\CrystalDiskInfo\DiskInfo.txt" "%userprofile%\Desktop\MCA-Logs\CrystalDiskLog.txt"


:: Uninstall CrystalDiskInfo silently
"%ProgramFiles%\CrystalDiskInfo\unins000.exe" /VERYSILENT /NORESTART /LOG="%userprofile%\Desktop\MCA-Logs\CrystalDiskInfo-Uninstall.log"


:: Import High Performance Power Plan & Make Primary
powercfg /import "high-performance.pow"
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo
echo High Performance Power Plan successfully imported and activated!
pause


:: Generates and exports logs pertaining to the health of the battery.
powercfg /batteryreport /output "%userprofile%\Desktop\MCA-Logs\Battery-Report.html"


:: CHKDSK & Filter Event Viewer to export logs
    chkdsk c:

    Powershell -Command "& "Get-winevent -FilterHashTable @{logname='Application'; id='26212'}^|?{$_.providername -match 'Chkdsk'} ^| fl timecreated, message ^| out-file '%userprofile%\Desktop\MCA-Logs\chkdsk.txt'"
    echo CHKDSK has been completed. Log file has been generated and exported.
    pause


:: DISM & Filter Event Viewer to export logs
    DISM /Online /Cleanup-Image /ScanHealth /NoRestart

    Powershell -Command "& "Get-winevent -FilterHashTable @{logname='Setup'; id='1014'}^|?{$_.providername -match 'Microsoft-Windows-Servicing'} ^| fl timecreated, message ^| out-file '%userprofile%\Desktop\MCA-Logs\DISM.txt'"

    echo DISM has been completed. Log file has been generated and exported.
    pause


:: SFC & Export logs
    sfc /scannow

    findstr /c:"[SR]" %windir%\Logs\CBS\CBS.log >"%userprofile%\Desktop\MCA-Logs\sfc-scannow.txt"

    echo SFC has been completed. Log file has been generated and exported.
    pause


:: Runs CCleaner off USB drive using last saved settings
    pause
    echo Verify custom clean settings on portable CCleaner version are correctly set before proceeding!
    pause
    "..\MyTools\CCleaner Portable\CCleaner64.exe" /auto


:: Check/Download/Install Windows Updates
:: Powershell -Command "& {Get-WindowsUpdate -AcceptAll -Install}"



exit /b