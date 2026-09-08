# Ask for machine name
$ComputerName = Read-Host "Enter computer name"

# Get disk info
Get-CimInstance Win32_LogicalDisk -ComputerName $ComputerName -Filter "DriveType=3" |
Select-Object `
    DeviceID,
    @{Name="Total(GB)";Expression={[math]::Round($_.Size / 1GB, 2)}},
    @{Name="Free(GB)";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
    @{Name="Free(%)";Expression={[math]::Round(($_.FreeSpace / $_.Size) * 100, 2)}},
    @{Name="Used(%)";Expression={[math]::Round((1 - ($_.FreeSpace / $_.Size)) * 100, 2)}} |
Format-Table -AutoSize