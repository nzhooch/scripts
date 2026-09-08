#Gets computer specs for any computer its run on
#Author Chris Trathen for CDHB

param (
    [Parameter(Position = 0)]
    [string]$ComputerName = $env:COMPUTERNAME
)

$ErrorActionPreference = 'Stop'

try {
    Write-Host "`nCollecting specifications from $ComputerName..." -ForegroundColor Cyan

    $cimParams = @{
        ComputerName = $ComputerName
    }

    # Use the local CIM connection without WinRM when querying this computer
    if ($ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq 'localhost' -or $ComputerName -eq '.') {
        $cimParams.Remove('ComputerName')
    }

    $computer = Get-CimInstance Win32_ComputerSystem @cimParams
    $os       = Get-CimInstance Win32_OperatingSystem @cimParams
    $cpu      = Get-CimInstance Win32_Processor @cimParams
    $gpu      = Get-CimInstance Win32_VideoController @cimParams
    $bios     = Get-CimInstance Win32_BIOS @cimParams
    $board    = Get-CimInstance Win32_BaseBoard @cimParams
    $disks    = Get-CimInstance Win32_DiskDrive @cimParams
    $volumes  = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" @cimParams
    $network  = Get-CimInstance Win32_NetworkAdapterConfiguration @cimParams |
                Where-Object { $_.IPEnabled }

    $ramModules = Get-CimInstance Win32_PhysicalMemory @cimParams

    $result = [ordered]@{
        'Computer Name'     = $computer.Name
        'Manufacturer'      = $computer.Manufacturer
        'Model'             = $computer.Model
        'Serial Number'     = $bios.SerialNumber
        'Motherboard'       = ($board | ForEach-Object {
                                  "$($_.Manufacturer) $($_.Product)"
                               }) -join '; '
        'BIOS Version'      = ($bios.SMBIOSBIOSVersion -join ', ')
        'BIOS Date'         = $bios.ReleaseDate
        'Windows Edition'   = $os.Caption
        'Windows Version'   = $os.Version
        'Windows Build'     = $os.BuildNumber
        'Architecture'      = $os.OSArchitecture
        'Last Boot'         = $os.LastBootUpTime
        'Uptime'            = (Get-Date) - $os.LastBootUpTime
        'CPU'               = ($cpu.Name -replace '\s+', ' ').Trim() -join '; '
        'CPU Cores'         = ($cpu | Measure-Object NumberOfCores -Sum).Sum
        'CPU Threads'       = ($cpu | Measure-Object NumberOfLogicalProcessors -Sum).Sum
        'Installed RAM GB'  = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
        'RAM Modules'       = ($ramModules | ForEach-Object {
                                  $size = [math]::Round($_.Capacity / 1GB, 0)
                                  $speed = if ($_.ConfiguredClockSpeed) {
                                      $_.ConfiguredClockSpeed
                                  } else {
                                      $_.Speed
                                  }
                                  "${size}GB $speed MHz $($_.Manufacturer) $($_.PartNumber.Trim())"
                               }) -join '; '
        'Video Card'        = ($gpu | ForEach-Object {
                                  $vram = if ($_.AdapterRAM) {
                                      "$([math]::Round($_.AdapterRAM / 1GB, 1)) GB"
                                  } else {
                                      'Unknown VRAM'
                                  }
                                  "$($_.Name) ($vram)"
                               }) -join '; '
        'Physical Disks'    = ($disks | ForEach-Object {
                                  $size = [math]::Round($_.Size / 1GB, 1)
                                  "$($_.Model) - $size GB - $($_.InterfaceType)"
                               }) -join '; '
        'Disk Volumes'      = ($volumes | ForEach-Object {
                                  $size = [math]::Round($_.Size / 1GB, 1)
                                  $free = [math]::Round($_.FreeSpace / 1GB, 1)
                                  "$($_.DeviceID) $free GB free of $size GB"
                               }) -join '; '
        'Network Adapters'  = ($network | ForEach-Object {
                                  $ip = ($_.IPAddress |
                                      Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }
                                  ) -join ', '

                                  "$($_.Description) | IP: $ip | MAC: $($_.MACAddress)"
                               }) -join '; '
    }

    Write-Host "`n===== COMPUTER SPECIFICATIONS =====" -ForegroundColor Green

    [pscustomobject]$result | Format-List

}
catch {
    Write-Host "`nFailed to collect specifications from $ComputerName." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}
