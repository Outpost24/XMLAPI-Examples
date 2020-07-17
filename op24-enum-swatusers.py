# SWAT user data script - Now in Python!
#  Author: Eren Cihangir
# Purpose: Request list of users from Outpost24 legacy XMLAPI. Use this list to
#          export CSV file to local dir titled "SWAT.csv". Intended to be executed by
#          splunk or other data aggregator for quick reference to user permissions
# Updates: 4/16/2020 - Creation date
#          4/21/2020 - Logic to handle JSON and csv
#          4/22/2020 - Adjusted logic to handle final output file, error checking
# Version: 0.3

import requests, json, pandas as pd

### Parameters ###
token = "<enter token here>"
base_url = "https://outscan.outpost24.com/opi/XMLAPI?";

#### FUNCTIONS ###
def get_users(base_url, token):
    
    # Obtain JSON formatted object containing all user data from Outscan
    print("Retrieving users from " + base_url)
    r = requests.get(base_url + "ACTION=SUBACCOUNTDATA&LIMIT=-1&ENCODING=utf-8&JSON=1&APPTOKEN=" + token)
    
    # Validate that both the request was received correctly, and that they are logged in
    if r.ok:
        
        if "error" not in r.text:
            print("Success...")
            return r
        else: 
            print(r.text)
            print("Error: Check that your token is valid by editing the script")
            quit()
    else:
        print("HTTP %i - %s, Message %s" % (r.status_code, r.reason, r.text))
        quit()

def main():
    # Obtain response from OP24 containing data
    response = get_users(base_url,token)
    
    # Extract data from response
    userdata = json.loads(response.text)
    
    # Interpret JSON data as a dictionary
    data = pd.DataFrame.from_dict(userdata['data'])
    
    # Define the list of headers for the output CSV
    header = ['FullName', 'Email', 'SuperUser', 'SWATLIST', 'SWATAPPLICATIONS']
    
    # Select and write data
    data_to_write = data[['vcfullname','vcemail','superuser','swatlist','swatapplications']]
    data_to_write.to_csv("SWAT.csv", index=False, header=header)
    

### Main program    
main()
