# This script is used to set the correct permissions so that PowerShell scripts can be run from Visual Studio.
set-executionpolicy -scope CurrentUser -executionPolicy RemoteSigned -force