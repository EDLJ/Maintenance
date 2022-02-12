@echo off

:: Elevate Privileges
    set "params=%*"
    cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

:: Create Restore Point
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -Command "Checkpoint-Computer -Description "MaintenanceVisit" -RestorePointType "MODIFY_SETTINGS"; " ' " -Verb RunAs; exit}"

:: Create Folder on Current Desktop for Exported Logs
    mkdir "%userprofile%\Desktop\MCA-Logs"

:: Generate and Export System Information
    Powershell -NoProfile -ExecutionPolicy Bypass -Command "& {get-computerinfo -property * | out-file "%userprofile%\Desktop\MCA-Logs\SystemInfo.txt"}
    cls
    echo System Info exported.
    pause

:: Export IPCONFIG
    ipconfig /all > "%userprofile%\Desktop\MCA-Logs\IPCONFIG.txt"
    cls
    echo IPConfig exported.
    pause

:: Install/Export Log/Uninstall CrystalDiskInfo
    echo Silently installing CrystalDiskInfo and exporting log. Please select Yes when the prompt to uninstall appears.
    "%~dp0\crystalDiskInstaller.exe" /VERYSILENT /NORESTART /MERGETASKS=!desktopicon64 /LOG="%userprofile%\Desktop\MCA-Logs\CrystalDiskInfo-Install.log"
    "%ProgramFiles%\CrystalDiskInfo\DiskInfo64.exe" /CopyExit
    move /y "%ProgramFiles%\CrystalDiskInfo\DiskInfo.txt" "%userprofile%\Desktop\MCA-Logs\CrystalDiskLog.txt"
    "%ProgramFiles%\CrystalDiskInfo\unins000.exe" /VERYSILENT /NORESTART /LOG="%userprofile%\Desktop\MCA-Logs\CrystalDiskInfo-Uninstall.log"
    cls
    echo CrystalDiskInfo log exported.
    pause
    cls

:: Set high performance power plan as primary/Generates and exports logs pertaining to the health of the battery.
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg /batteryreport /output "%userprofile%\Desktop\MCA-Logs\Battery-Report.html"
    cls
    echo Battery Report exported and High Performance Power Plan activated.
    pause
    cls

:: CHKDSK & Filter Event Viewer to export logs
    echo "Running CHKDSK..."
    chkdsk c:
    Powershell -Command "& "Get-winevent -FilterHashTable @{logname='Application'; id='26212'}^|?{$_.providername -match 'Chkdsk'} ^| fl timecreated, message ^| out-file '%userprofile%\Desktop\MCA-Logs\chkdsk.txt'"
    cls
    echo CHKDSK has been completed. Log file has been generated and exported.
    pause
    cls

:: DISM & Filter Event Viewer to export logs
    echo "Running DISM"
    DISM /Online /Cleanup-Image /ScanHealth /NoRestart
    Powershell -Command "& "Get-winevent -FilterHashTable @{logname='Setup'; id='1014'}^|?{$_.providername -match 'Microsoft-Windows-Servicing'} ^| fl timecreated, message ^| out-file '%userprofile%\Desktop\MCA-Logs\DISM.txt'"
    cls
    echo DISM has been completed. Log file has been generated and exported.
    pause
    cls

:: SFC & Export logs
    echo "Running SFC..."
    sfc /scannow
    findstr /c:"[SR]" %windir%\Logs\CBS\CBS.log >"%userprofile%\Desktop\MCA-Logs\sfc-scannow.txt"
    cls
    echo SFC has been completed. Log file has been generated and exported.
    pause
    cls

:: Runs CCleaner off USB drive using last saved settings
    echo Verify custom clean settings on portable CCleaner version are correctly set before proceeding!
    pause
    pause
    "%~dp0\CCleaner Portable\CCleaner64.exe" /auto
    cls
    echo CCleaner custom clean completed.
    pause
    cls

:: Exports Group Policy
    echo Running GPO Report...
    gpresult /h %userprofile%\Desktop\MCA-Logs\GroupPolicy-Report.html
    echo GPO Report exported.
    pause
    cls

:: Check/Download/Install Windows Updates
    echo Final Step in Script - Installs All Windows Updates and Gives Option of Rebooting
    echo Exit script now if you prefer to skip this step.
    pause
    Powershell -NoProfile -ExecutionPolicy Bypass -Command "& {Install-Module -Name PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install; Get-WUHistory | out-file -FilePath %userprofile%\Desktop\MCA-Logs\WindowsUpdateHistory.txt}
    cls
    echo Windows Updates have been downloaded and installed. Log exported.
    pause

exit /b