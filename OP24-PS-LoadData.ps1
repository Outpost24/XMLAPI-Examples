<#
Project Name: OP24-PS-LoadData.ps1
      Author: Eren Cihangir
        Date: 9/9/2019
     Purpose: Allow user to pull basic data about targets and findings. Designed to be edited on use.
      Inputs: None
    Comments: Findings target is set to -1, not any specific assset. Unknown what -1 does but it returns some data.
Intended Use: Modify as needed to acquire target and findings data.

#>

# Initialization
# Set TLS 1.2 requirement and define important variables
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$token = 'APPTOKEN=5BD96410B2A7B12D93AD659EFA34282E3EBD52AF4C76607C0F01937466532163'
$uri = "https://outscan.outpost24.com/opi/XMLAPI?"


# Request for asset data in JSON format
#
$response = curl -uri ("https://outscan.outpost24.com/opi/XMLAPI?ACTION=TARGETDATA&JSON=1&" + $token)
$json = ConvertFrom-Json $response.Content
$json.data | ConvertTo-Json > targetdata.json


# Request for findings data in JSON format
#
$response = curl -uri ("https://outscan.outpost24.com/opi/XMLAPI?ACTION=REPORTTARGETDATA&GROUPS=%2C-1%2C&TARGETS=-1&JSON=1&" + $token)
$json = ConvertFrom-Json $response.Content
$json.data | ConvertTo-Json > findingsdata.json