# Note: This script was designed to be used with Powershell Version 5.1, Using in any other Powershell version may cause errors


Write-Host "Starting Script, Please wait..." -ForegroundColor green
""

# Set variables
$scriptpath = ".\Delprof2.exe"
$assetlist = Get-Content -Path ".\Assets.txt"
$datenow = Get-Date -Format "dd-MM-yyyy"
$timenow = Get-Date -Format "HHmm"
$logfolder = ".\Logs\$datenow"
$logfile = "${logfolder}\Device_Status-$timenow.txt"


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
# Call above function
"Checking folder path: '$logfolder'..."
checklogpath $logfolder "Directory"
"Checking file path: '$logfile'..."
checklogpath $logfile "File"


# Cycles throguh each asset in the given list, tests if they are online and calls Delprof2 function if the asset is online. If the asset is offline, create record of asset in log file.
"Reading file: .\Assets.txt"
ForEach ($line in $assetlist) {
    $splitstring = $line.split()
    $asset = $splitstring[0]

    # Runs Delprof2 in a new window for the given asset number
    function rundelprofscript{
        Write-Host "Running Delprof2 in new window..." -ForegroundColor green
        $command = "$scriptpath /u /C:$asset"
        Start-Process Powershell -ArgumentList "-NoExit", "-Command &{$command} ; Write-Host '' ; Write-Host 'Process Finished.' -ForegroundColor green ; Write-Host '' "
    }

    # Does a quick ping test to see if the given asset number is online
    Write-Host "Testing connection to asset: $asset" -ForegroundColor yellow
    if (Test-Connection -ComputerName $asset -Count 2 -Delay 1 -Quiet){

        # Updates Log file with asset status
        Add-Content -Path $logfile -Value "$asset Status: In Progress"

        # Calls the function that runs Delprof2
        rundelprofscript
    }
    # Provides feedback if the asset number is offline
    else {
        Write-Host "Error: $asset Offline" -ForegroundColor red
        Add-Content -Path $logfile -Value "$asset Status: Offline"
    }

}

# End of script and wait for user input before closing window
""
Write-Host "End Of Script." -ForegroundColor green
""
Read-Host -Prompt "Press Enter to exit."


