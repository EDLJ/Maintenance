$YYYYMMDD = Get-Date -format "yyyyMMdd"

$model = Get-WmiObject Win32_ComputerSystem | Select-Object Manufacturer, Model
$model | ConvertTo-Json | Set-Content "%~dp0\$YYYYMMDD-Logs\MaintenanceReportData.json"
$hostname = Get-WmiObject Win32_ComputerSystem | Select-Object Name
$hostname | ConvertTo-Json | Add-Content "%~dp0\$YYYYMMDD-Logs\MaintenanceReportData.json"
$serial = Get-WmiObject Win32_bios | Select-Object SerialNumber
$serial | ConvertTo-Json | Add-Content "%~dp0\$YYYYMMDD-Logs\MaintenanceReportData.json"
$os = (Get-WmiObject -class Win32_OperatingSystem).Caption
$os | ConvertTo-Json | Add-Content "%~dp0\$YYYYMMDD-Logs\MaintenanceReportData.json"
$ram = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb
$ram | ConvertTo-Json | Add-Content "%~dp0\$YYYYMMDD-Logs\MaintenanceReportData.json"
$drivespace = Get-CimInstance win32_logicaldisk | Where-Object caption -eq "C:" | foreach-object {Write-Output " $($_.caption) $('{0:N2}' -f ($_.Size/1gb)) GB total, $('{0:N2}' -f ($_.FreeSpace/1gb)) GB free "}
$drivespace | ConvertTo-Json | Add-Content "%~dp0\$YYYYMMDD-Logs\MaintenanceReportData.json"