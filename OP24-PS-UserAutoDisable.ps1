<#
Project Name: OP24-PS-UserAutoDisable.ps1
      Author: Eren Cihangir
        Date: 9/29/2019
     Purpose: Request user input for specially formatted CSV source. Use data to create user accounts within OP24 platform of choice.
      Inputs: APPTOKEN: Obtained from UI by going to Settings->Account->Security Policy->Application Access Tokens
                Example will look like this: 2BB94BC9A2465F5A136AE6DC62CC56A622D59246EE4FBCD6542D03B63502C723

              URI
                for Outscan/SWAT/Snapshot/Assure, this will be outscan.outpost24.com
                for internal use, this will be https://hiab-hostname.yourdomain

       Usage: OP24-PS-UserAutoDisable.ps1 -uri "https://hiab.youroganization.com/opi/XMLAPI?" -token 2BB94BC9A2465F5A136AE6DC62CC56A622D59246EE4FBCD6542D03B63502C723
              OP24-PS-UserAutoDisable.ps1 -token 2BB94BC9A2465F5A136AE6DC62CC56A622D59246EE4FBCD6542D03B63502C723

    Comments: This is intended to be run ad-hoc or automatically with a scheduling mechanism such as Task Scheduler.

#>

param (
    [Parameter(Mandatory=$True)][string]$token,
    [string]$uri = "https://outscan.outpost24.com/opi/XMLAPI?"
)

Add-Type -AssemblyName System.Web

# Initialization
# Set TLS 1.2 requirement and define important variables
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Variable initialization
$token = 'APPTOKEN=' + $token # note the existence of the "APPTOKEN=" in this string

#Function definitions

# Function to retrieve users from API and display the user XIDs
function Get-Users($token) {
    #How to request user account list/data in JSON format
    $response = curl -uri ("https://outscan.outpost24.com/opi/XMLAPI?ACTION=SUBACCOUNTDATA&JSON=1&" + $token)
    $json = ConvertFrom-Json $response.Content
    return $json.data
}

function AutoDisable-Users($users) {

    # Loop to iterate over imported data and determine which users haven't logged in recently.
    # Those who have not logged in recently are disabled until they are enabled manually later.
    # Also setting the ChangePasswordOnLogon flag to True. This is optional.
    foreach ($user in $users) {
        
        if (!($user.dlastlogon) -gt (get-date).AddDays(-30)) {
            # Build message 
            $msg =  "&ACTION=UPDATESUBACCOUNTDATA" + 
                    "&JSON=1" + 
                    "&XID=" + $user.xid + 
                    "&BACTIVE=0" + 
                    "&CHANGEPASSWORDONLOGON=1"

            write-host "User " $user.vcusername "has not logged in for 30 or more days. Disabling them."

            # Send final request
            $response = Invoke-WebRequest -uri ($uri+$token+$msg)
            # Post response for execution log
            $response
        }
        else { 
            write-host "User " $user.vcusername "has logged in recently and will remain enabled." 
        }
    }
}

# Basic logic:
#  Get list of users
#  Parse list, disable users as needed
#  End

$users = Get-Users $token
AutoDisable-Users $users
# End