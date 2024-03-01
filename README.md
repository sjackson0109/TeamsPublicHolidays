# Public Holidays Management for Microsoft Teams Schedule

This PowerShell script automates the management of public holidays in Microsoft Teams schedules. It fetches public holiday data from an external API and updates the designated schedule in Microsoft Teams accordingly.

##

Author: Simon Jackson (@sjackson0109)
Date: 10/02/2024
Special Thanks: Bjoren Dassow (@dassbj01) for a hint to use the `date.nager.at` REST api service. 


## Features

- **Dynamic Holiday Retrieval**: The script fetches public holiday data dynamically from an external API based on the provided country code and year.
- **Schedule Update**: It updates the specified Microsoft Teams schedule with the fetched public holidays, ensuring the schedule is up-to-date. TIP: Dozens of call flows (auto-attendants), can have an out-of-holidays action attached to a single schedule - giving one table of holidays to update!
- **Modular Design**: The code is modularized with separate functions for fetching data and updating the schedule, making it easy to maintain and reuse.

## How to Use

1. **Requirements**: Ensure that you have the required PowerShell modules installed, including the Microsoft Teams module.
2. **Import the Script**: Import the PowerShell script into your environment.
3. **Update Parameters**: Modify the parameters in the script as needed, including the schedule name and country code.
4. **Execute the Script**: Run the `Update-PublicHolidays` function with the desired parameters to update the schedule.

## Examples

1. Updating the *existing* Schedule called `UK National Holidays, use the following:
```powershell
#Commands
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
.\Update-TeamsPublicHolidays.ps1
Update-PublicHolidays -ScheduleName 'UK National Holidays' -CountryCode 'GB'
#Output
UPDATING: UK National Holidays
CURRENT SCHEDULE:

Start               End                
-----               ---                
01/01/2024 00:00:00 02/01/2024 00:00:00


NEW SCHEDULE:

Start               End                
-----               ---                
01/01/2024 00:00:00 02/01/2024 00:00:00
02/01/2024 00:00:00 03/01/2024 00:00:00
17/03/2024 00:00:00 18/03/2024 00:00:00
29/03/2024 00:00:00 30/03/2024 00:00:00
01/04/2024 00:00:00 02/04/2024 00:00:00
06/05/2024 00:00:00 07/05/2024 00:00:00
27/05/2024 00:00:00 28/05/2024 00:00:00
12/07/2024 00:00:00 13/07/2024 00:00:00
05/08/2024 00:00:00 06/08/2024 00:00:00
26/08/2024 00:00:00 27/08/2024 00:00:00
30/11/2024 00:00:00 01/12/2024 00:00:00
25/12/2024 00:00:00 26/12/2024 00:00:00
26/12/2024 00:00:00 27/12/2024 00:00:00
```