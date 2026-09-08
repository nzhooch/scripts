#removes word perfect office....
## Uninstall WPS office ##
$ComputerName = Read-Host "Enter computer name"

Invoke-Command -ComputerName $ComputerName -ScriptBlock {

    Write-Host "`n=== Checking for WPS Office ===" -ForegroundColor Cyan

    $wpsApps = Get-ItemProperty `
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", `
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match "WPS|Kingsoft" }

    if (-not $wpsApps) {
        Write-Host "WPS Office not found." -ForegroundColor Green
    }
    else {
        Write-Host "Found WPS Office:" -ForegroundColor Yellow
        $wpsApps | Select-Object DisplayName, DisplayVersion, UninstallString | Format-Table -AutoSize

        Write-Host "`nStopping WPS processes..." -ForegroundColor Cyan
        Get-Process wps, et, wpp, wpscloudsvr -ErrorAction SilentlyContinue | Stop-Process -Force

        foreach ($app in $wpsApps) {
            if ($app.UninstallString) {
                Write-Host "Running uninstall for $($app.DisplayName)..." -ForegroundColor Cyan

                $uninstall = $app.UninstallString

                if ($uninstall -match "MsiExec") {
                    $guid = ($uninstall -replace ".*?({.*}).*", '$1')
                    Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait
                }
                else {
                    Start-Process "cmd.exe" -ArgumentList "/c `"$uninstall`" /silent /verysilent /quiet /norestart" -Wait
                }
            }
        }
    }

    Write-Host "`nCleaning leftovers..." -ForegroundColor Cyan

    $paths = @(
        "C:\Program Files\Kingsoft",
        "C:\Program Files (x86)\Kingsoft",
        "C:\Program Files\WPS Office",
        "C:\Program Files (x86)\WPS Office",
        "C:\ProgramData\Kingsoft",
        "C:\ProgramData\WPS Office"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $userPath = $_.FullName

        $userLeftovers = @(
            "$userPath\AppData\Roaming\Kingsoft",
            "$userPath\AppData\Local\Kingsoft",
            "$userPath\AppData\Roaming\WPS Office",
            "$userPath\AppData\Local\WPS Office"
        )

        foreach ($folder in $userLeftovers) {
            if (Test-Path $folder) {
                Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Write-Host "`n=== Final WPS Check ===" -ForegroundColor Cyan

    $finalCheck = Get-ItemProperty `
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", `
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match "WPS|Kingsoft" }

    if ($finalCheck) {
        Write-Host "WPS may still be installed:" -ForegroundColor Red
        $finalCheck | Select-Object DisplayName, DisplayVersion, UninstallString | Format-Table -AutoSize
    }
    else {
        Write-Host "WPS Office successfully removed." -ForegroundColor Green
    }
}
