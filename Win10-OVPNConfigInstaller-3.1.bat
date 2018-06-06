@ECHO OFF
cd /D %UserProfile%\ovpn_scripts
PowerShell.exe -Windowstyle Hidden -ExecutionPolicy Bypass -Command "& '%~dpn0.ps1'"
Pause