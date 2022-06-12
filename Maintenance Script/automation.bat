@echo off
setlocal
:: Elevate Privileges
    set "params=%*"
    cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
:: Create Restore Point
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command "Checkpoint-Computer -Description "MaintenanceVisit" -RestorePointType "MODIFY_SETTINGS"; " ' " -Verb RunAs; exit}"
:: Set variable for current date and hostname
    set YYYYMMDD=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
    set computerName=hostname
:: Create Folder on Current Desktop for Exported Logs
    mkdir "%~dp0\Logs"
:: Removes ProductKey tool from Windows Defender quarantined list and exports log of what else is in there
    "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Restore -Name "HackTool:Win32/ProductKey"
    "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Restore -ListAll > "%~dp0\Logs\WindowsDefender-QuarantinedItems.txt"
:: Generate and Export Fully-Detailed System Information
    Powershell -NoProfile -ExecutionPolicy Bypass -Command "& {get-computerinfo -property * | out-file '%~dp0\Logs\SystemInfo.txt'}"
    echo System Info exported.
:: Export StartUp Applications
    wmic startup get caption,command > "%~dp0\Logs\StartUpApplications.txt"
:: Maintenance Report Data
    :: System Model / Hostname / Serial Number / OS Version / RAM / HDD Total / HDD Free
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\MaintenanceReportData.ps1"
:: Export CPU-Z Log
    "%~dp0\CPU-Z\cpuz_x64.exe" -html="%~dp0\Logs\CPU-Z"
    echo CPU-Z report exported.
:: Network Information
    netsh wlan show wlanreport
    move /y "%ProgramData%\Microsoft\Windows\wlanreport\wlan-report-latest.html" "%~dp0\Logs\wlan-report-latest.html"
    echo Network Analysis completed.
:: Speedtest
    "%~dp0\speedtest.exe" --accept-license > "%~dp0\Logs\SpeedTest.txt"
:: Install/Export Log/Uninstall CrystalDiskInfo
    echo Silently installing CrystalDiskInfo and exporting log. Please select Yes when the prompt to uninstall appears.
    "%~dp0\crystalDiskInstaller.exe" /VERYSILENT /NORESTART /MERGETASKS=!desktopicon64 /LOG="%~dp0\Logs\CrystalDiskInfo-Install.log"
    "%ProgramFiles%\CrystalDiskInfo\DiskInfo64.exe" /CopyExit
    move /y "%ProgramFiles%\CrystalDiskInfo\DiskInfo.txt" "%~dp0\Logs\CrystalDiskLog.txt"
    "%ProgramFiles%\CrystalDiskInfo\unins000.exe" /VERYSILENT /NORESTART /LOG="%~dp0\Logs\CrystalDiskInfo-Uninstall.log"
    echo CrystalDiskInfo log exported.
:: Set high performance power plan as primary/Generates and exports logs pertaining to the health of the battery.
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg /batteryreport /output "%~dp0\Logs\Battery-Report.html"
    echo Battery Report exported and High Performance Power Plan activated.
:: CHKDSK & Filter Event Viewer to export logs
    echo Running CHKDSK...
    chkdsk c:
    Powershell -Command "& "Get-winevent -FilterHashTable @{logname='Application'; id='26212'}^|?{$_.providername -match 'Chkdsk'} ^| fl timecreated, message ^| out-file '%~dp0\Logs\chkdsk.txt'"
    echo CHKDSK has been completed. Log file has been generated and exported.
:: DISM & Filter Event Viewer to export logs
    echo Running DISM
    DISM /Online /Cleanup-Image /ScanHealth /NoRestart
    Powershell -Command "& "Get-winevent -FilterHashTable @{logname='Setup'; id='1014'}^|?{$_.providername -match 'Microsoft-Windows-Servicing'} ^| fl timecreated, message ^| out-file '%~dp0\Logs\DISM.txt'"
    echo DISM has been completed. Log file has been generated and exported.
:: SFC & Export logs
    echo Running SFC...
    sfc /scannow
    findstr /c:"[SR]" %windir%\Logs\CBS\CBS.log >"%~dp0\Logs\sfc-scannow.txt"
    echo SFC has been completed. Log file has been generated and exported.
:: Runs CCleaner off USB drive using last saved settings
    "%~dp0\CCleaner Portable\CCleaner64.exe" /auto
    echo CCleaner custom clean completed.
:: Exports Group Policy
    echo Running GPO Report...
    gpresult /H "%~dp0\Logs\GroupPolicy-Report.html"
    echo GPO Report exported.
:: Exports Windows/Office/SQL/IE/Exchange Product Keys
produkey.exe /WindowsKeys 1 /OfficeKeys 1 /IEKeys 1 /SQLKeys 1 /ExchangeKeys 1 /ExtractEdition 1 /sjson "%~dp0\Logs\ProduKey.json"
:: Compresses logs folder using 7Zip
    7za.exe a -tzip ".\%YYYYMMDD%\%USERNAME%.zip" "%~dp0\Logs\*"
::  Removes log folder
    rmdir /Q /S "%~dp0\Logs"

                            :: Check/Download/Install Windows Updates
                            ::    echo Final Step in Script - Installs All Windows Updates and Gives Option of Rebooting
                            ::    Powershell -NoProfile -ExecutionPolicy Bypass -Command "& {Install-Module -Name PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install; Get-WUHistory | out-file -FilePath %~dp0\Logs\WindowsUpdateHistory.txt}"

                            :: Checks if Windows Update Logs have been generated. If so, will exit.
                            ::    IF EXIST "%~dp0\Logs\WindowsUpdateHistory.txt" EXIT