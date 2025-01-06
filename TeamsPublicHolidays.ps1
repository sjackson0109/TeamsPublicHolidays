<#
.SYNOPSIS
    TeamsPublicHolidays.ps1 - Script to manage public holidays in Microsoft Teams schedules.

.DESCRIPTION
    This script fetches public holiday data from an external API and updates the designated schedule in Microsoft Teams accordingly.

.EXAMPLE
    Update-TeamsPublicHolidays -ScheduleName 'UK National Holidays' -CountryCode 'GB'
    #This command updates the 'UK National Holidays' schedule in Microsoft Teams with the public holidays for the United Kingdom. Default behaviour is append, but can be overuled with the "-NotAppend" switch. 
    It will only add the future holidays, all past holidays will not be added. 

    New-TeamsPublicHolidays -ScheduleName 'FR National Holidays' -CountryCode 'FR' - Region 'FR'
    # This command creates a new schedule named 'FR National Holidays' in Microsoft Teams and attaches the public holidays for France. 
    It will only add the future holidays, all past holidays will not be added. 
    
    New-TeamsPublicHolidays -ScheduleName 'DE Regional Bavaria Holidays' -CountryCode 'DE' -Region 'BY'
    # This command creates a new schedule named 'DE Regional Bavaria Holidays' in Microsoft Teams and attaches the National public holidays for Germany including the Regional holidays for the Region (Bavaria). 
    It will only add the future holidays, all past holidays will not be added. 


.NOTES
    File Name      	: TeamsPublicHolidays.ps1
    Author         	: Simon Jackson (@sjackson0109)
    Contributors	: Mitchell Bakker (mitchelljb)
    Prerequisite   	: PowerShell 3.0 or above, Microsoft Teams module installed
    Created     	: 2023/12/20
    Updated         : 2025/01/03
    Version         : 1.03

.LINK
    https://github.com/sjackson0109/TeamsScheduleNationalHolidays
    https://blog.jacksonfamily.me/Teams-ScheduleNationalHolidays
#>

function Get-PublicHolidays {
    Param(
        [string]$CountryCode = "GB",
        [string]$Region = "ENG",
        [int]$Year = (Get-Date).Year
    )

    $url = "https://date.nager.at/api/v3/PublicHolidays/$Year/$CountryCode"
    Write-Host "Fetching holidays from URL: $url"

    try {
        $holidaysResponse = Invoke-RestMethod -Uri $url -Method "GET"
    } catch {
        Write-Error "An error occurred while fetching holidays for country code ($CountryCode) and year ($Year)"
        return @()
    }

    # Filter holidays (Global or Region-specific)
    $filteredHolidays = $holidaysResponse | Where-Object {
        ($_.Global -eq $true) -or (
            $_.Counties -and (
                ($_.Counties -replace "$CountryCode-", "" -split "[,|&]") -contains $Region
            )
        )
    }

    # Process and clean up holidays
    $processedHolidays = $filteredHolidays | ForEach-Object {
        [PSCustomObject]@{
            Date        = $_.date
            Name        = $_.name
            Global      = $_.global
            CountryCode = $_.countryCode
            Counties    = if ($_.Counties) { ($_.Counties -replace "$CountryCode-", "" -join ", ") } else { "" }
        }
    }

    # Return the processed holidays
    return $processedHolidays
}
function New-TeamsPublicHolidays {
    Param(
        [string]$CountryCode = "GB",
        [string]$Region = "",
        [string]$ScheduleName = "UK National Holidays",
        [int]$Year = (Get-Date).Year
    )

    try {
        # Get public holidays for the specified country code and year
        $holidays = Get-PublicHolidays -CountryCode $CountryCode -Year $Year -Region $Region
    } catch {
        Write-Error "An error occurred while fetching holidays for country code ($CountryCode) and year ($Year)"
        Write-Host "TIP: Check you have supplied the correct CountryCode from the following website: https://www.iban.com/country-codes"
        return
    }

    # Define a date range some time in the past, so it won't be relevant
    $initialDateTimeRange = New-CsOnlineDateTimeRange -Start "01/01/1900" -End "02/01/1900"
    # Create a new CsOnlineSchedule for the specified schedule name
    $schedule = New-CsOnlineSchedule -Name "$ScheduleName" -FixedSchedule -DateTimeRanges $initialDateTimeRange

    # Ensure DateTimeRanges is initialized
    if (-not $schedule.FixedSchedule.DateTimeRanges) {
        $schedule.FixedSchedule.DateTimeRanges = @()
    }

    # Add holidays to the schedule
    foreach ($holiday in $holidays) {
        $myDate = [datetime]::ParseExact($holiday.Date, 'yyyy-MM-dd', $null)
        $DateStart = $myDate.ToString('dd/MM/yyyy 00:00')
        $DateEnd = $myDate.AddDays(1).ToString('dd/MM/yyyy 00:00')

        Write-Host "Processing holiday: $($holiday.Name) on $DateStart to $DateEnd"

        try {
            # Add the holiday to the schedule
            $dateTimeRange = New-CsOnlineDateTimeRange -Start $DateStart -End $DateEnd
            $schedule.FixedSchedule.DateTimeRanges += $dateTimeRange
        } catch {
            Write-Error "Failed to add holiday: $($holiday.Name) on $DateStart to $DateEnd. Error: $_"
        }
    }

    # Remove all historical events
    $schedule.FixedSchedule.DateTimeRanges = $schedule.FixedSchedule.DateTimeRanges | Where-Object { $_.End -ge (Get-Date) }

    # Output the dates added to the schedule
    Write-Host "Dates added to schedule '$ScheduleName':"
    $schedule.FixedSchedule.DateTimeRanges | Format-Table -Property Start, End -AutoSize

    # Update the schedule in Microsoft Teams
    try {
        Set-CsOnlineSchedule -Instance $schedule | Out-Null
        Write-Host "Schedule '$ScheduleName' updated successfully."
    } catch {
        Write-Error "Failed to update schedule '$ScheduleName'. Error: $_"
    }
}
function Update-TeamsPublicHolidays {
    Param(
        [string]$CountryCode = "GB",
        [string]$Region = "ENG", # Add Region Parameter
        [string]$ScheduleName = "UK National Holidays",
        [int]$Year = (Get-Date).Year,
        [switch]$Replace = $false
    )
    
    try {
        # Get public holidays for the specified country code, year, and region
        $holidays = Get-PublicHolidays -CountryCode $CountryCode -Year $Year -Region $Region
    } catch {
        Write-Error "An error occurred while fetching holidays for country code ($CountryCode), year ($Year), and region ($Region)"
        return
    }

    # Retrieve existing schedule
    $existingSchedule = Get-CsOnlineSchedule | Where-Object { $_.Name -eq "$ScheduleName" }
    if ($null -eq $existingSchedule) {
        Write-Error "No existing schedule found with name '$ScheduleName'"
        return
    }

    # Output the current dates in the schedule
    Write-Host "CURRENT DATES:"
    $existingSchedule.FixedSchedule.DateTimeRanges | Format-Table -Property Start, End -AutoSize

    if (-not $Replace) {
        foreach ($holiday in $holidays) {
            $myDate = [datetime]::ParseExact($holiday.Date, 'yyyy-MM-dd', $null)
            $DateStart = $myDate.ToString('dd/MM/yyyy 00:00')
            $DateEnd = $myDate.AddDays(1).ToString('dd/MM/yyyy 00:00')

            if ($existingSchedule.FixedSchedule.DateTimeRanges.Start -notcontains $holiday.Date) {
                $dateTimeRange = New-CsOnlineDateTimeRange -Start $DateStart -End $DateEnd
                $existingSchedule.FixedSchedule.DateTimeRanges += $dateTimeRange
            }
        }

        # Prune past dates
        $existingSchedule.FixedSchedule.DateTimeRanges = $existingSchedule.FixedSchedule.DateTimeRanges | Where-Object { $_.End -ge (Get-Date) }

        # Output the new dates added to the schedule
        Write-Host "NEW DATES:"
        $existingSchedule.FixedSchedule.DateTimeRanges | Format-Table -Property Start, End -AutoSize

        # Update the schedule in Microsoft Teams
        Set-CsOnlineSchedule -Instance $existingSchedule | Out-Null
    } else {
        # Replace logic here (if needed)
        Write-Host "Replace functionality is not implemented in this example." -ForegroundColor Yellow
    }
}
function Prune-TeamsPublicHolidays {
    Param(
        [string]$ScheduleName = "UK National Holidays"
    )

    # Retrieve existing schedule
    $existingSchedule = Get-CsOnlineSchedule | Where-Object { $_.Name -eq "$ScheduleName" }
    if ($null -eq $existingSchedule) {
        Write-Error "No existing schedule found with name '$ScheduleName'"
        return
    }

    # Output the current dates in the schedule
    Write-Host "CURRENT DATES:"
    $existingSchedule.FixedSchedule.DateTimeRanges | Format-Table -Property Start, End -AutoSize

    # Prune past dates
    $existingSchedule.FixedSchedule.DateTimeRanges = $existingSchedule.FixedSchedule.DateTimeRanges | Where-Object { $_.End -ge (Get-Date) }

    # Output the remaining dates in the schedule
    Write-Host "REMAINING DATES AFTER PRUNING:"
    $existingSchedule.FixedSchedule.DateTimeRanges | Format-Table -Property Start, End -AutoSize

    # Update the schedule in Microsoft Teams
    Set-CsOnlineSchedule -Instance $existingSchedule | Out-Null
    Write-Host "Schedule '$ScheduleName' pruned successfully."
}