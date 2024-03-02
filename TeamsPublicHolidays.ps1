<#
.SYNOPSIS
    Update-TeamsPublicHolidays.ps1 - Script to manage public holidays in Microsoft Teams schedules.

.DESCRIPTION
    This script fetches public holiday data from an external API and updates the designated schedule in Microsoft Teams accordingly.

.EXAMPLE
    Update-TeamsPublicHolidays -ScheduleName 'UK National Holidays' -CountryCode 'GB'
    #This command updates the 'UK National Holidays' schedule in Microsoft Teams with the public holidays for the United Kingdom.

    Create-TeamsPublicHolidays -ScheduleName 'FR National Holidays' -CountryCode 'FR'
    # This command creates a new schedule named 'FR National Holidays' in Microsoft Teams and attaches the public holidays for France.


.NOTES
    File Name      : Update-TeamsPublicHolidays.ps1
    Author         : Simon Jackson (@sjackson0109)
    Prerequisite   : PowerShell 3.0 or above, Microsoft Teams module installed
    Last Modified  : 2024/03/01

.LINK
    https://github.com/sjackson0109/TeamsScheduleNationalHolidays
    https://blog.jacksonfamily.me/Teams-ScheduleNationalHolidays
#>

function Get-PublicHolidays {
    Param(
        [string]$CountryCode= "GB"
    )
    $year = Get-Date -Format yyyy
    $url = "https://date.nager.at/api/v3/PublicHolidays/$year/$CountryCode"
    $holidaysResponse = Invoke-RestMethod -Uri $url -Method "GET"
    $holidays = $holidaysResponse | ForEach-Object {
        [PSCustomObject]@{
            Date = $_.date
            Name = $_.name
        }
    }
    return $holidays
}
function Update-TeamsPublicHolidays {
    Param(
        [string]$CountryCode= "GB",
        [string]$ScheduleName= "UK National Holidays"
    )
    $holidays = Get-PublicHolidays -CountryCode $CountryCode
    $schedule = Get-CsOnlineSchedule | Where-Object { $_.Name -eq $ScheduleName }
    Write-Host "UPDATING: $($schedule.Name)"
    Write-Host "CURRENT DATES:"
    $schedule.FixedSchedule.DateTimeRanges | Format-Table
    $schedule.FixedSchedule.DateTimeRanges = @()
    foreach ($holiday in $holidays) {
        $myDate = [datetime]::ParseExact($holiday.Date, 'yyyy-MM-dd', $null)
        $DateStart = $myDate.ToString('dd/MM/yyyy 00:00')
        $DateEnd = $myDate.AddDays(1).ToString('dd/MM/yyyy 00:00')
        $schedule.FixedSchedule.DateTimeRanges += New-CsOnlineDateTimeRange -Start $DateStart -End $DateEnd
    }
    Write-Host "NEW DATES:"
    $schedule.FixedSchedule.DateTimeRanges | Format-Table
    Set-CsOnlineSchedule -Instance $schedule | Out-Null
}

# function Create-TeamsPublicHolidays {
#     Param(
#         [string]$CountryCode= "FR",
#         [string]$ScheduleName= "FR National Holidays"
#     )

#     # Check if a schedule with the provided name already exists
#     $existingSchedule = Get-CsOnlineSchedule | Where-Object { $_.Name -eq $ScheduleName }

#     if ($existingSchedule) {
#         Write-Host "EXISTING SCHEDULE: $($existingSchedule.Name)"
#         $schedule = $existingSchedule
#     } else {
#         # Create an empty array for DateTimeRanges
#         $dateTimeRanges = @()

#         # Create a new schedule with FixedSchedule initialized with DateTimeRanges
#         $schedule = New-CsOnlineSchedule -Name $ScheduleName -FixedSchedule @{DateTimeRanges = $dateTimeRanges}

#         Write-Host "NEW SCHEDULE: $($schedule.Name)"
#     }

#     # Attach public holidays to the schedule
#     $holidays = Get-PublicHolidays -CountryCode $CountryCode
#     foreach ($holiday in $holidays) {
#         $myDate = [datetime]::ParseExact($holiday.Date, 'yyyy-MM-dd', $null)
#         $DateStart = $myDate.ToString('dd/MM/yyyy 00:00')
#         $DateEnd = $myDate.AddDays(1).ToString('dd/MM/yyyy 00:00')
#         $schedule.FixedSchedule.DateTimeRanges += New-CsOnlineDateTimeRange -Start $DateStart -End $DateEnd
#     }

#     # Output the updated schedule
#     Write-Host "NEW DATES: $($schedule.Name)"
#     $schedule.FixedSchedule.DateTimeRanges | Format-Table

#     # Update the schedule
#     Set-CsOnlineSchedule -Instance $schedule | Out-Null
# }
