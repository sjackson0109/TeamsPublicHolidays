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
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
.\Update-TeamsPublicHolidays.ps1
Update-PublicHolidays -ScheduleName 'UK National Holidays' -CountryCode 'GB'
```
![UK 2024 Example](/Examples/UK_2024.png")


2. Updating the *existing* Schedule called `DE National Holidays, use the following:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
.\Update-TeamsPublicHolidays.ps1
Update-PublicHolidays -ScheduleName 'UK National Holidays' -CountryCode 'GB'
```
![DE 2024 Example](.\Examples\DE_2024.png")


## Don't have an *existing* Schedule
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