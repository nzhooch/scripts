# Note: This script was designed to be used with Powershell Version 5.1, Using in any other Powershell version may cause errors


Write-Host "Starting Script, Please wait..." -ForegroundColor green
""

# Set variables
$assetlist = Get-Content -Path ".\Assets.txt"
$datenow = Get-Date -Format "dd-MM-yyyy"
$timenow = Get-Date -Format "HHmm"
$logfolder = ".\Logs\$datenow"
$logfile = "${logfolder}\Diskspace-$timenow.txt"


# Checks the filepath for the log folder and files, and creates them if they don't exist
function checklogpath([string]$path, [string] $type){
    if (-Not (Test-Path -Path $path)){
        Write-Host "Path not found, creating path..." -ForegroundColor yellow
        New-Item -Path $path -ItemType $type
        ""
        Write-Host "Path created." -ForegroundColor green
        ""
    }
}
"Checking folder path: '$logfolder'..."
checklogpath $logfolder "Directory"
"Checking file path: '$logfile'..."
checklogpath $logfile "File"

"Reading file: .\Assets.txt"
# Cycles throguh each asset in the given list, tests if they are online and writes their available diskspace in GB to a log file
ForEach ($line in $assetlist){
    $splitline = $line.Split()
    $asset = $splitline[0]
    Write-Host "Testing connection to asset: $asset" -ForegroundColor yellow
    if (Test-Connection -ComputerName $asset -Count 2 -Delay 1 -Quiet){
        try{
            Write-Host "Attempting to get disk space for asset: $asset" -ForegroundColor yellow
            $diskspaceraw = Get-WmiObject -ClassName Win32_LogicalDisk -ComputerName $asset -Filter "DeviceID = 'C:'"
            $freespace = [math]::Round($diskspaceraw.FreeSpace / 1GB, 2)
            Write-Host "Logging disk space to file: $logfile" -ForegroundColor yellow
            ""
            Add-Content -Path $logfile -Value "$asset Freespace: ${freespace}GB"
        }
        catch{
            Write-Host "Unknown Error: $asset" -ForegroundColor red
            ""
            Add-Content -Path $logfile -Value "$asset Freespace: Unknown Error"
        }
    }
    else {
        Write-Host "Error: $asset is Offline" -ForegroundColor red
        ""
        Add-Content -Path $logfile -Value "$asset Freespace: Offline"
    }
}

# End of script and wait for user input before closing window
""
Write-Host "End Of Script." -ForegroundColor green
""
Read-Host -Prompt "Press Enter to exit."

