<#
Project Name: OP24-PS-ImportUsersFromCsv.ps1
      Author: Eren Cihangir
        Date: 9/29/2019
     Purpose: Read specially formatted CSV source. Use data to create user accounts within OP24 platform of choice.
      Inputs: Csv file containing the following: 
                VCCOUNTRY: The country for this account
                VCEMAIL: The email address associated with this user account
                VCFIRSTNAME: The first name of the user
                VCLASTNAME: The surname of the user
                VCUSERNAME: String - the alias the user logs in with. Automatically converted to uppercase when consumed by API
                VCPHONEMOBILE: Integer - Format: "12345678910" (does not currently autovalidate if this format is not followed: PLEASE follow it!)
                USERGROUPLIST: List of user roles (0 or more) to assign to user. 
                                 Format: Comma-separated and terminated ("1234,1235,").
                                   Note that the final comma is automatically accounted for in the $msg string builder already with "%2c".
                SENDEMAILNOTIFICATION: Boolean. Determines if the user account should have an email notification sent
                BACTIVE: Boolean. Determines if the user account should be enabled or disabled. 0=disabled, 1=enabled
                EMAILENCRYPTIONKEY: User-defined string. "Unencrypted" is default. Does not need to be defined for user creation, but is necessary for
                                    configuring user to receive email event notifications and reports.
                XISUBPARENTID: Integer - XID of Parent user account (for user definition)
                TICKETPARENT: Integer - XID of Ticket Parent user account (for ticket escalation)
                CHANGEPASSWORDONLOGON: Boolean. Determines if the user account needs to select a new password upon login


              APPTOKEN: Obtained from UI by going to Settings->Account->Security Policy->Application Access Tokens
                Example will look like this: 2BB94BC9A2465F5A136AE6DC62CC56A622D59246EE4FBCD6542D03B63502C723

              URI
                for Outscan/SWAT/Snapshot/Assure, this will be outscan.outpost24.com
                for internal use, this will be https://hiab-hostname.yourdomain

       Usage: OP24-PS-ImportUsersFromCsv.ps1 -uri "https://outscan.outpost24.com/opi/XMLAPI?" -token 2BB94BC9A2465F5A136AE6DC62CC56A622D59246EE4FBCD6542D03B63502C723 -filepath "C:\path\file.csv" -auto $false
              OP24-PS-ImportUsersFromCsv.ps1 -token 2BB94BC9A2465F5A136AE6DC62CC56A622D59246EE4FBCD6542D03B63502C723 -auto $true

     Options: 1 = List Current Users
              2 = List Roles
              3 = Import Users from filepath
              4 = Display Imported Users
              5 = Upload Users to Outpost24
              q = Exit

    Comments: This is intended to take a list of users from CSV file and create those users in Outscan/HIAB. 
              In order for this to add user roles, Role XIDs must be obtained and added into the spreadsheet request. 


Intended Use: User is supplied with template CSV file. After filling in some data, they'll run script and use it to identify role XIDs to finish filling csv.
              Once the CSV file is completed, user can re-import and validate before submitting to OP24 API.
              This can run without user interaction with the -auto flag set to $True, but must always have token

#>

param (
    [Parameter(Mandatory=$True)][string]$Token = "2BB94BC9A2465F5A136AE6DC62CC56A622D59246EE4FBCD6542D03B63502C723",
    [string]$filepath = "C:\path\file.csv",
    [string]$uri = "https://outscan.outpost24.com/opi/XMLAPI?",
    [bool]$auto = $false
)

Add-Type -AssemblyName System.Web

# Initialization
# Set TLS 1.2 requirement and define important variables
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Variable initialization
$apptoken = 'APPTOKEN=' + $token # note the existence of the "APPTOKEN=" in this string

#Function definitions
# Function to display the user XIDs from a user list
function Display-RoleXIDs($apptoken) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $response = curl -uri ($uri + "ACTION=USERGROUPDATA&JSON=1&" + $apptoken)
    $json = ConvertFrom-Json $response.Content

    #Example iterating over and printing role names and xids from objects
    foreach ($role in $json.data) {
        Write-Host "Role Name: "$role.vcname
        Write-host "      XID: "$role.xid
    }
}

# Function to retrieve users from API and display the user XIDs
function Display-UserXIDs($apptoken) {
    #How to request user account list/data in JSON format
    $response = curl -uri ($uri + "ACTION=SUBACCOUNTDATA&JSON=1&" + $apptoken)
    $json = ConvertFrom-Json $response.Content


    #Example iterating over and printing usernames from objects
    foreach ($user in $json.data) {
        Write-Host "Username: "$user.vcusername 
        write-Host "     XID: "$user.xid
    }
}

# Function to import the userlist from a csv file
function Import-UserList($filepath) {
    $import = Import-Csv $filepath
    return $import
}

# Function to convert true and false into 1 and 0
function boolToBinary($string) {
    If ($string -like "true") {
        return 1
    } elseif ($string -like "false") {
        return 0
    } else {
        return $string # do nothing, API ignores invalid data
    }
}

function Upload-Users($users) {
    $users

    # Loop to iterate over imported data and submit requests for user creation.
    foreach ($user in $users) {
        
        # Input validation
        $user.USERGROUPLIST      = [System.Web.HttpUtility]::UrlEncode($user.USERGROUPLIST)
        $user.VCPASSWORD         = [System.Web.HttpUtility]::UrlEncode($user.VCPASSWORD)
        $user.EMAILENCRYPTIONKEY = [System.Web.HttpUtility]::UrlEncode($user.EMAILENCRYPTIONKEY)
        $user.VCFIRSTNAME        = [System.Web.HttpUtility]::UrlEncode($user.VCFIRSTNAME)
        $user.VCLASTNAME         = [System.Web.HttpUtility]::UrlEncode($user.VCLASTNAME)
    
        If (!$user.USERGROUPLIST.EndsWith('%2c')) {
            $user.USERGROUPLIST = ($user.USERGROUPLIST + "%2c")
        }

        # Convert "trues" and "falses" into boolean
        $user.SENDEMAILNOTIFICATION = boolToBinary $user.SENDEMAILNOTIFICATION
        $user.CHANGEPASSWORDONLOGON = boolToBinary $user.CHANGEPASSWORDONLOGON
        $user.BACTIVE               = boolToBinary $user.BACTIVE


        # Build message 
        $msg =  "&ACTION=UPDATESUBACCOUNTDATA" + 
                "&JSON=1" + 
                "&VCUSERNAME=" + $user.VCUSERNAME +
                "&VCFIRSTNAME=" + $user.VCFIRSTNAME + 
                "&VCLASTNAME=" + $user.VCLASTNAME + 
                "&VCPHONEMOBILE=" + $user.VCPHONEMOBILE + 
                "&XID=" + $user.XID + 
                "&VCCOUNTRY=" + $user.VCCOUNTRY.ToLower() + 
                "&TICKETPARENT=" + $user.TICKETPARENT + 
                "&VCPASSWORD=" + $user.VCPASSWORD + 
                "&USERGROUPLIST=" + $user.USERGROUPLIST + 
                "&XISUBPARENTID=" + $user.XISUBPARENTID + 
                "&BACTIVE=" + $user.BACTIVE + 
                "&SENDEMAILNOTIFICATION=" + $user.SENDEMAILNOTIFICATION + 
                "&CHANGEPASSWORDONLOGON=" + $user.CHANGEPASSWORDONLOGON + 
                "&EMAILENCRYPTIONKEY=" + $user.EMAILENCRYPTIONKEY + 
                "&VCEMAIL=" + $user.VCEMAIL 

        # Troubleshooting
        # Print built request string
        #write-host "message: $msg"
        #($uri+$apptoken+$msg)

        # Send final request
        $response = Invoke-WebRequest -uri ($uri+$apptoken+$msg)
    
        # Post response for execution log
        $response
    }
}

If ($auto) {
    $users = Import-UserList $filepath
    Upload-Users $users
}
else {
   While ($selection -notlike "q") {
    # Method for allowing user input and reiterating until quit
        Write-Host "Please make a selection:"
        Write-Host "1 = List Current Users"
        Write-Host "2 = List Roles"
        Write-Host "3 = Import Users from filepath"
        Write-Host "4 = Display Imported Users"
        Write-Host "5 = Upload Users to Outpost24"
        Write-Host "q = Exit"
        $selection = Read-Host
        switch ($selection) {
           # Case 1: Display the User XIDs
           "1"  { Display-UserXIDs($apptoken); break}
           # Case 2: Display the Role XIDs
           "2"  { Display-RoleXIDs($apptoken); break}
           # Case 3: Import users from $FilePath
           "3"  {
                  write-host "Attempting to import users from "$filepath
                  write-host "Use option 4 to validate data"
                  $users = Import-UserList $filepath; break
                }
           # Case 4: Display imported users so that user may validate
           "4"  { $users; break }
           # Case 5: Upload users to Outpost24
           "5"  {
              if ($users -eq $null) 
                { write-host "You must import users first!"; break }
              else 
                { Upload-Users $users; break }
           }
        }
    }
}



$users = $null
$selection = $null