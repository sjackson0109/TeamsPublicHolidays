<#
.SYNOPSIS
    Update-TeamsPublicHolidays.ps1 - Script to manage public holidays in Microsoft Teams schedules.

.DESCRIPTION
    This script fetches public holiday data from an external API and updates the designated schedule in Microsoft Teams accordingly.

.PARAMETER ScheduleName
    Specifies the name of the Microsoft Teams schedule to update.

.PARAMETER CountryCode
    Specifies the country code for which to fetch public holidays.

.EXAMPLE
    Update-TeamsPublicHolidays -ScheduleName 'UK National Holidays' -CountryCode 'UK'

    This command updates the 'UK National Holidays' schedule in Microsoft Teams with the public holidays for the United Kingdom.

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
        [string]$CountryCode= "UK"
    )
    $year = Get-Date -Format yyyy
    $url = "https://date.nager.at/api/v3/PublicHolidays/$year/$CountryCode"
    $holidaysResponse = Invoke-RestMethod -Uri $url -Method "GET"
    $holidays = $holidaysResponse | ForEach-Object {
        [PSCustomObject]@{
            Date = $_.date
            LocalName = $_.localName
            Name = $_.name
        }
    }
    return $holidays
}
function Update-PublicHolidays {
    Param(
        [string]$CountryCode= "UK",
        [string]$ScheduleName= "UK National Holidays"
    )
    $holidays = Get-PublicHolidays -CountryCode $CountryCode
    $schedule = Get-CsOnlineSchedule | Where-Object { $_.Name -eq $ScheduleName }
    Write-Host "UPDATING: $($schedule.Name)"
    Write-Host "CURRENT SCHEDULE:"
    $schedule.FixedSchedule.DateTimeRanges | Format-Table
    $schedule.FixedSchedule.DateTimeRanges = @()
    foreach ($holiday in $holidays) {
        $myDate = [datetime]::ParseExact($holiday.Date, 'yyyy-MM-dd', $null)
        $DateStart = $myDate.ToString('dd/MM/yyyy 00:00')
        $DateEnd = $myDate.AddDays(1).ToString('dd/MM/yyyy 00:00')
        $schedule.FixedSchedule.DateTimeRanges += New-CsOnlineDateTimeRange -Start $DateStart -End $DateEnd
    }
    Write-Host "NEW SCHEDULE:"
    $schedule.FixedSchedule.DateTimeRanges | Format-Table
    Set-CsOnlineSchedule -Instance $schedule | Out-Null
}