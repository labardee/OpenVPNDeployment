#This script was written by Ansen Labardee in October of 2018.
#The purpose of the script is to download and install a configuration from our OpenVPN Access Server on the Users machine.
#This script does not require Local Admin permissions but the access server will not provide a configuration to a user that has not been granted VPN Access.  
#
#
#Get the user name of the currently logged in user and convert it into a username that openvpn recognizes. 
$REGIONAL = "REGIONAL"
$DOLANMEDIA = "DOLANMEDIA"
$loggedinuser = $env:UserName
$userdomain = $env:UserDomain
If ($userdomain -ieq $REGIONAL) {$ovpnuser = $loggedinuser + "@regional.dolanmedia.com"}
If ($userdomain -ieq $DOLANMEDIA) {$ovpnuser = $loggedinuser}

#Specify Path and Name for  new configuration file.
$NewConfigPath = "C:\Program Files\OpenVPN\config\"
$ConfFile = $NewConfigPath + $loggedinuser + ".ovpn"

#Check to make sure that the path exists before we go any further. 
if ((Test-Path $NewConfigPath) -eq $false) {
    $wshell = New-Object -ComObject Wscript.Shell
    $UserResponse1 = $wshell.Popup("The configuration path is missing, OpenVPN may not be installed. Would you like to create the path anyway?",0,"Path is Missing",0x4 + 0x30)}
#If the directory doesn't exist, ask the user if we should create it
if ($UserResponse1 -eq "6") {New-Item $NewConfigPath -type directory -ErrorVariable builddirerror;}
#If the user wants to create the directory and we can't, tell the user and exit
    if ($builddirerror) {
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup("You do not have permission to do that, most likely Group Policy has not processed yet. Try again later or contact the Service Desk and provide them with this error:`n `n$builddirerror", 0, "No Permisson to do that", 0x0 + 0x30)
    exit 1}
#If the user doesnt want to create the directory then don't and exit
if ($UserResponse1 -eq "7") {exit 1}

#If the path exists remove all OpenVPN configurations inside.
if ((Test-Path $NewConfigPath) -eq $true) {Get-ChildItem 'C:\Program Files\OpenVPN\config\' -Include *.ovpn -recurse | foreach ($_) {remove-item $_.fullname}}

#Next, force tls 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Specify the Url to be fetched
$url = "https://vpn.bridgetowermedia.com/rest/GetUserlogin"

#Collect the users password, if they won't, tell them to piss off.
$Cred = $Host.ui.PromptForCredential("OpenVPN Needs Credentials", "Please enter your Computer password.", "$loggedinuser", "")
if ($Cred -eq $null) { 
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup("You must enter a username and password to install a configuration.", 0, "Identification Please", 0x0 + 0x30)
        exit 1}
$User = $ovpnuser
$Pass = $Cred.GetNetworkCredential().Password
$pair = "${User}:${Pass}"

#Take the username and password and combine it into an HTTP Basic Auth header. 
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
$headers = @{ Authorization = $basicAuthValue }

#Now, request the configuration file and place it in the OpenVPN Configuration Directory.
Invoke-WebRequest -Uri $url -Headers $headers -OutFile $ConfFile -ErrorVariable getconfigerror;

#If we can't get the configuration tell the enduser
If ($getconfigerror) {
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Please try again. Either your password is incorrect, you do not have permission to access VPN, or the server is unavailable. Error:`n `n$getconfigerror", 0, "Sorry, something went wrong.", 0x0 + 0x30)
    exit 1}

#Check to make sure that a configuration file was installed, tell the user.
$GeneratedFileName = Get-ChildItem 'C:\Program Files\OpenVPN\config\' -Include *.ovpn -recurse -Name
If ($GeneratedFileName) {
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Your configuration file $NewConfigPath$GeneratedFileName has been installed successfully, You may now use OpenVPN ", 0, "Saul Goodman!", 0x0 + 0x40)
    exit 0} Else {
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Please contact the Service Desk, something went wrong and your configuration was not installed.", 0, "Sorry, something went wrong.", 0x0 + 0x30)
    exit 1}