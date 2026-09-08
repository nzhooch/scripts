#Medchart file and folder creation and permissions - asks for PC name when script is run.
# Version 1.1
$Computer = Read-Host "Enter asset/computer name"

Invoke-Command -ComputerName $Computer -ScriptBlock {

    $RootFolder    = "C:\Medchart_OfflineCharts"
    $Canterbury    = "C:\Medchart_OfflineCharts\Canterbury"
    $ShareName     = "Medchart_OfflineCharts"
    $Group         = "FIL-MedchartOCLAdmin-Mod"
    $Svc           = "srv-medcav10@cdhb.local"
    $ShortcutPath  = "C:\Users\Public\Desktop\Test OCL.lnk"

    # Create folders
    New-Item -Path $RootFolder -ItemType Directory -Force | Out-Null
    New-Item -Path $Canterbury -ItemType Directory -Force | Out-Null

    # Create SMB share if required
    if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {

        New-SmbShare `
            -Name $ShareName `
            -Path $RootFolder `
            -ChangeAccess $Group, $Svc | Out-Null
    }
    else {

        # Remove Everyone from SMB share
        Revoke-SmbShareAccess `
            -Name $ShareName `
            -AccountName "Everyone" `
            -Force `
            -ErrorAction SilentlyContinue

        # Allow both MedChart accounts to modify data through the share
        Grant-SmbShareAccess `
            -Name $ShareName `
            -AccountName $Group `
            -AccessRight Change `
            -Force

        Grant-SmbShareAccess `
            -Name $ShareName `
            -AccountName $Svc `
            -AccessRight Change `
            -Force
    }

    # Ensure Everyone is not granted SMB access
    Revoke-SmbShareAccess `
        -Name $ShareName `
        -AccountName "Everyone" `
        -Force `
        -ErrorAction SilentlyContinue

    # NTFS permissions on Canterbury and everything underneath it
    icacls $Canterbury /grant "${Group}:(OI)(CI)(M)" | Out-Null
    icacls $Canterbury /grant "${Svc}:(OI)(CI)(M)" | Out-Null

    # Everyone can read Canterbury and everything underneath it
    icacls $Canterbury /grant "Everyone:(OI)(CI)(R)" | Out-Null

    # Create public desktop shortcut directly to Canterbury
    $Shell = New-Object -ComObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut($ShortcutPath)

    $Shortcut.TargetPath = "\\$env:COMPUTERNAME\$ShareName\Canterbury"
    $Shortcut.Description = "Test OCL"
    $Shortcut.Save()

    Write-Host ""
    Write-Host "Configuration complete on $env:COMPUTERNAME" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access configured for:"
    Write-Host "  \\$env:COMPUTERNAME\$ShareName\Canterbury"
    Write-Host ""
    Write-Host "$Group : SMB Change + NTFS Modify"
    Write-Host "$Svc   : SMB Change + NTFS Modify"
}
