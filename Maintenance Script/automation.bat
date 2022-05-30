@echo off

:: Elevate Privileges
    set "params=%*"
    cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

:: Create Restore Point
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command "Checkpoint-Computer -Description "MaintenanceVisit" -RestorePointType "MODIFY_SETTINGS"; " ' " -Verb RunAs; exit}"

:: Set variable for current date and hostname
    set YYYYMMDD=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
    set computerName=hostname

:: Create Folder on Current Desktop for Exported Logs
    mkdir "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs"

:: Generate and Export Fully-Detailed System Information
    Powershell -NoProfile -ExecutionPolicy Bypass -Command "& {get-computerinfo -property * | out-file '%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\SystemInfo.txt'}"
    cls
    echo System Info exported.

:: Export StartUp Applications
    wmic startup get caption,command > "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\StartUpApplications.txt"

:: Maintenance Report Data
    :: System Model / Hostname / Serial Number / OS Version / RAM / HDD Total / HDD Free
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\MaintenanceReportData.ps1"

:: Export CPU-Z Log
    "%~dp0\CPU-Z\cpuz_x64.exe" -html="%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\CPU-Z"
    cls
    echo CPU-Z report exported.

:: Network Information
    netsh wlan show wlanreport
    move /y "%ProgramData%\Microsoft\Windows\wlanreport\wlan-report-latest.html" "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\wlan-report-latest.html"
    cls
    echo Network Analysis completed.

:: Speedtest
    "%~dp0\speedtest.exe" > "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\SpeedTest.txt"

:: Install/Export Log/Uninstall CrystalDiskInfo
    echo Silently installing CrystalDiskInfo and exporting log. Please select Yes when the prompt to uninstall appears.
    "%~dp0\crystalDiskInstaller.exe" /VERYSILENT /NORESTART /MERGETASKS=!desktopicon64 /LOG="%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\CrystalDiskInfo-Install.log"
    "%ProgramFiles%\CrystalDiskInfo\DiskInfo64.exe" /CopyExit
    move /y "%ProgramFiles%\CrystalDiskInfo\DiskInfo.txt" "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\CrystalDiskLog.txt"
    "%ProgramFiles%\CrystalDiskInfo\unins000.exe" /VERYSILENT /NORESTART /LOG="%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\CrystalDiskInfo-Uninstall.log"
    cls
    echo CrystalDiskInfo log exported.

:: Set high performance power plan as primary/Generates and exports logs pertaining to the health of the battery.
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg /batteryreport /output "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\Battery-Report.html"
    cls
    echo Battery Report exported and High Performance Power Plan activated.

:: CHKDSK & Filter Event Viewer to export logs
    echo Running CHKDSK...
    chkdsk c:
    Powershell -Command "& "Get-winevent -FilterHashTable @{logname='Application'; id='26212'}^|?{$_.providername -match 'Chkdsk'} ^| fl timecreated, message ^| out-file '%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\chkdsk.txt'"
    cls
    echo CHKDSK has been completed. Log file has been generated and exported.

:: DISM & Filter Event Viewer to export logs
    echo Running DISM
    DISM /Online /Cleanup-Image /ScanHealth /NoRestart
    Powershell -Command "& "Get-winevent -FilterHashTable @{logname='Setup'; id='1014'}^|?{$_.providername -match 'Microsoft-Windows-Servicing'} ^| fl timecreated, message ^| out-file '%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\DISM.txt'"
    cls
    echo DISM has been completed. Log file has been generated and exported.

:: SFC & Export logs
    echo Running SFC...
    sfc /scannow
    findstr /c:"[SR]" %windir%\Logs\CBS\CBS.log >"%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\sfc-scannow.txt"
    cls
    echo SFC has been completed. Log file has been generated and exported.

:: Runs CCleaner off USB drive using last saved settings
    "%~dp0\CCleaner Portable\CCleaner64.exe" /auto
    cls
    echo CCleaner custom clean completed.

:: Exports Group Policy
    echo Running GPO Report...
    gpresult /H "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\GroupPolicy-Report.html"
    echo GPO Report exported.

:: Compresses logs folder using 7Zip
    7za.exe a -tzip ".\%YYYYMMDD%.zip" "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\*"

::  Removes old folder on user desktop
    rmdir /Q /S "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs"

:: Check/Download/Install Windows Updates
::    echo Final Step in Script - Installs All Windows Updates and Gives Option of Rebooting
::    Powershell -NoProfile -ExecutionPolicy Bypass -Command "& {Install-Module -Name PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install; Get-WUHistory | out-file -FilePath %userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\WindowsUpdateHistory.txt}"

:: Checks if Windows Update Logs have been generated. If so, will exit.
::    IF EXIST "%userprofile%\Desktop\%YYYYMMDD%-MaintenanceLogs\WindowsUpdateHistory.txt" EXIT