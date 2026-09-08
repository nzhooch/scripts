#Clean up and repair ccm cache
#Written by Chris Trathen, for DHB


$Computer = Read-Host "Enter computer name"

Invoke-Command -ComputerName $Computer -ScriptBlock {

    Write-Host "`n=== Restarting SCCM Service ===" -ForegroundColor Cyan
    Restart-Service CcmExec -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 5

    Write-Host "`n=== Stopping Software Center Processes ===" -ForegroundColor Cyan
    Get-Process SCClient, SoftwareCenter -ErrorAction SilentlyContinue | Stop-Process -Force

    Write-Host "`n=== Clearing CCM Cache ===" -ForegroundColor Cyan

    $CachePath = "C:\Windows\CCMCache"

    if (Test-Path $CachePath) {
        Get-ChildItem $CachePath -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Cache cleared"
    }
    else {
        Write-Host "CCMCache folder not found"
    }

    Write-Host "`n=== Checking Services ===" -ForegroundColor Cyan

    Get-Service CcmExec, BITS, wuauserv |
    Select Name, Status

    Write-Host "`n=== Running SCCM Repair ===" -ForegroundColor Cyan

    $Repair = "C:\Windows\CCM\ccmrepair.exe"

    if (Test-Path $Repair) {
        Start-Process $Repair -Wait
        Write-Host "ccmrepair started"
    }
    else {
        Write-Host "ccmrepair.exe not found"
    }

    Write-Host "`n=== Launching Software Center ===" -ForegroundColor Cyan

    Start-Process "softwarecenter:"

    Write-Host "`n=== Done ===" -ForegroundColor Green
}
