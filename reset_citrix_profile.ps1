#Resets a usernames citrix profile, works on DHB and also WC

$Username = read-host "Enter Username"
$Option = read-host "Select Domain | 1: cdhb | 2: westcoastdhb"
switch ($option) {
        1 {$Domain = "cdhb"}
        2 {$Domain = "westcoastdhb"}
        }

$Profile = "\\mschcctxupmp01\citrixupm$\prd\$Domain\$Username\"
$Pending = "$Profile" + "Pending"
$UPM = "$Profile" + "UPM_Profile"

write-host "Username: $Username"
write-host "Domain: $Domain"
write-host $Pending
write-host $UPM

Read-host "Confirm the above and press any button to continue, or CTRL + C to cancel"

Get-ChildItem -Path $UPM -File | Remove-Item -Include "NTUSER.DAT","NTUSER.DAT.LASTGOODLOAD"

Get-ChildItem -Path $Pending -Directory | ForEach-Object {
    $Folder = "$Pending" + "\" + "$_"
    write-host "Deleting $Folder"
    &cmd.exe /c rd /s /q $Folder
}
