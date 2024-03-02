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
4. **Execute the Script**: Run the `Update-TeamsPublicHolidays` function with the desired parameters to update the schedule.

### Examples

1. Updating the *existing* Schedule called `UK National Holidays, use the following:
- ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
  Import-Module .\TeamsPublicHolidays.ps1
  Update-TeamsPublicHolidays -ScheduleName 'UK National Holidays' -CountryCode 'GB'
  ```

2. Updating the *existing* Schedule called `DE National Holidays, use the following:
- ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
  Import-Module .\TeamsPublicHolidays.ps1
  Update-TeamsPublicHolidays -ScheduleName 'DE National Holidays' -CountryCode 'DE'
  ```

|Command|Result|
|---|---|
|![UK 2024 Command](/Examples/UK_2024.png)|![UK 2024 Result](/Examples/UK_2024_Result.png)|
|![DE 2024 Command](/Examples/DE_2024.png)|![DE 2024 Result](/Examples/DE_2024_Result.png)|


## Where do the country codes come from?
You can look up your country code (2-digits) from [here](https://www.iban.com/country-codes).


## Are you forgetting the *existing* Schedule?
Maybe create one... here you go:
```poweshell
$scheduleName="UK National Holidays"    ### UPDATE THIS SPELLING
Import-Module MicrosoftTeams
Connect-MicrosoftTeams
$today = Get-Date -Format "yyyy-MM-dd";
$dateStart="$today 00:00"; $dateEnd="$today 23:59";
$schedule = New-CsOnlineSchedule -Name $scheduleName
$schedule.FixedSchedule.DateTimeRanges = @()
$schedule.FixedSchedule.DateTimeRanges += New-CsOnlineDateTimeRange -Start $dateStart -End $dateEnd
Set-CsOnlineSchedule -Instance $schedule
Write-Host "You can now use the .\Update-TeamsPublicHolidays.ps1 file to update your new schedule ($ScheduleName)"
```


## Conflicting Schedules?
Having experienced this issue myself, i figured i'd explain it.
```powershell
Correlation id for this request : 41825f04-a34b-4513-a905-43945ae17645
Microsoft.Teams.ConfigAPI.Cmdlets.internal\Set-CsOnlineSchedule : The changes made in Schedule 83e774b4-eabf-478f-914e-56966515a9b3 are causing conflicts with other schedules in Auto Attendant 70561269-5dc8-485c-b125-5a75ab90ebed. Error: Holidays within an auto
attendant cannot start at the same date-time.
```
Root-cause is relatively simple: I had 'UK National Holidays' and 'Company Closures' schedules  to a single auto-attendant. Our company is closed for 3-days during the christmas period, and I figured i'd add them in manually.  I slipped a day, and boxing day overlapped with the 'UK National Holidays' for 2024.

Pretty simple fix: ensure both schedules don't conflict. nice and easy.

