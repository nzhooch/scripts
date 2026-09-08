ConfigureUserPackage.ps1


# ConfigureUserPackage
# Cameron Logan

function Set-WindowStyle {
param(
    [Parameter()]
    [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE', 
                 'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED', 
                 'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
    $Style = 'SHOW',
    [Parameter()]
    $MainWindowHandle = (Get-Process -Id $pid).MainWindowHandle
)
    $WindowStates = @{
        FORCEMINIMIZE   = 11; HIDE            = 0
        MAXIMIZE        = 3;  MINIMIZE        = 6
        RESTORE         = 9;  SHOW            = 5
        SHOWDEFAULT     = 10; SHOWMAXIMIZED   = 3
        SHOWMINIMIZED   = 2;  SHOWMINNOACTIVE = 7
        SHOWNA          = 8;  SHOWNOACTIVATE  = 4
        SHOWNORMAL      = 1
    }
    Write-Verbose ("Set Window Style {1} on handle {0}" -f $MainWindowHandle, $($WindowStates[$style]))

    $Win32ShowWindowAsync = Add-Type –memberDefinition @” 
    [DllImport("user32.dll")] 
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru

    $Win32ShowWindowAsync::ShowWindowAsync($MainWindowHandle, $WindowStates[$Style]) | Out-Null
}


# Get the user name
$UserName =  $env:username

# The source path
$SourcePath = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent

$CacheTargetPath = "C:\Users\$UserName\.cache\icedtea-web\jvm-cache"

############## this part is REM'd out for testing ##################
# Delete folder if exist
#If (Test-Path -Path "$CacheTargetPath") {
#	
#	& cmd /c RMdir /S /Q "$CacheTargetPath"
#}
########## my script change ###############

# Fix: Rename existing icedtea-web cache if it exists
if (Test-Path -Path "$CacheTargetPath") {
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupPath = "$CacheTargetPath.old-$timestamp"
Rename-Item -Path "$CacheTargetPath" -NewName $BackupPath -Force
}
########## end of my change#########

New-Item $CacheTargetPath -itemtype directory -force | Out-Null

Copy-Item -path "$SourcePath\PerUserFiles\.cache\icedtea-web\jvm-cache\cache.json" -Destination "$CacheTargetPath" -Force

$ConfigTargetPath = "C:\Users\$UserName\.config\icedtea-web"

New-Item $ConfigTargetPath -itemtype directory -force | Out-Null

Copy-Item -path "$SourcePath\PerUserFiles\.config\icedtea-web\deployment.properties" -Destination "$ConfigTargetPath" -Force

Copy-Item -path "$SourcePath\PerUserFiles\.config\icedtea-web\.appletTrustSettings" -Destination "$ConfigTargetPath" -Force

$ConfigSecurityTargetPath = "C:\Users\$UserName\.config\icedtea-web\Security"

New-Item $ConfigSecurityTargetPath -itemtype directory -force | Out-Null

Copy-Item -path "$SourcePath\PerUserFiles\.config\icedtea-web\security\trusted.certs" -Destination "$ConfigSecurityTargetPath" -Force
Copy-Item -path "$SourcePath\PerUserFiles\.config\icedtea-web\security\java.policy" -Destination "$ConfigSecurityTargetPath" -Force

# Start Process
Start-Process -FilePath '"C:\Program Files\OpenWebStart\javaws.exe"' -ArgumentList '"C:\Program Files (x86)\DURAsuite\launchDS.jnlp"'

Start-Sleep -s 35

(Get-Process -Name java).MainWindowHandle | foreach { Set-WindowStyle MAXIMIZE $_ }
