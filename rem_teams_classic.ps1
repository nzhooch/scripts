#Removes MS Teams Classic from PC, asks for PC Name

$Computer = Read-Host "Enter computer name"

Invoke-Command -ComputerName $Computer -ScriptBlock {

    $appName = "Microsoft Teams classic"

    # A function to search for Teams installation
    function Get-MSTeams {
        $path = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        )

        $entry = Get-ChildItem -Path $path -ErrorAction SilentlyContinue |
            Get-ItemProperty -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -match $appName }

        return $entry
    }

    # Find Teams Classic
    $app = Get-MSTeams

    if ($app) {

        Write-Output "Microsoft Teams Classic installation FOUND on $env:COMPUTERNAME."

        # Run uninstall
        Set-Location -Path $app.InstallLocation
        Start-Process Update.exe -ArgumentList "--uninstall", "-s"
        Write-Output "`nUninstalling..."

        Start-Sleep 5

        # Keep checking until Teams Classic is gone
        while (Get-MSTeams) {
            Start-Sleep 2
            Write-Output "Uninstalling..."
        }

        Write-Output "`nMicrosoft Teams Classic successfully uninstalled from $env:COMPUTERNAME!`n"
    }
    else {
        Write-Output "Microsoft Teams Classic installation NOT found on $env:COMPUTERNAME."
    }

    Set-Location $HOME
}
```
