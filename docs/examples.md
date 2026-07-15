---
title: Examples
---

[Home](index.md) · [Background](background.md) · [Use Cases](use-cases.md) · [Automation & Pipelines](automation.md) · [Examples](examples.md) · [FAQ](faq.md)

# Examples

All examples assume you've already connected interactively (`Connect-MicrosoftTeams`) and imported the module (`Import-Module .\TeamsPublicHolidays.ps1`) as described on the [Home](index.md) page. For the unattended, multi-customer version of these same operations, see [Automation & Pipelines](automation.md).

## Creating a new schedule

Create a new schedule called `UK National Holidays`, filtered to England only, for the current year:

```powershell
New-TeamsPublicHolidays -ScheduleName 'UK National Holidays' -CountryCode 'GB' -Region 'ENG'
```

| Command | Result |
|---|---|
| ![UK 2024 Command](https://raw.githubusercontent.com/sjackson0109/TeamsPublicHolidays/main/Examples/UK_2024.png) | ![UK 2024 Result](https://raw.githubusercontent.com/sjackson0109/TeamsPublicHolidays/main/Examples/UK_2024_Result.png) |

## Updating an existing schedule for a specific year

```powershell
Update-TeamsPublicHolidays -ScheduleName 'DE National Holidays' -CountryCode 'DE' -Year '2024'
```

| Command | Result |
|---|---|
| ![DE 2024 Command](https://raw.githubusercontent.com/sjackson0109/TeamsPublicHolidays/main/Examples/DE_2024.png) | ![DE 2024 Result](https://raw.githubusercontent.com/sjackson0109/TeamsPublicHolidays/main/Examples/DE_2024_Result.png) |

## Filtering to a region

Germany's public holidays vary by federal state. This creates/updates a schedule for Berlin only:

```powershell
Update-TeamsPublicHolidays -ScheduleName 'Berlin Holidays' -CountryCode 'DE' -Region 'BE'
```

And for Poland, for 2025:

```powershell
Update-TeamsPublicHolidays -ScheduleName 'Polish National Holidays' -CountryCode 'PL' -Year '2025'
```

## Previewing what a query will return

Before wiring a schedule up, it's worth checking what `Get-PublicHolidays` actually returns for a given country and region - this is the same data `New-`/`Update-TeamsPublicHolidays` will write into the schedule.

```powershell
Get-PublicHolidays | ft

Fetching holidays from URL: https://date.nager.at/api/v3/PublicHolidays/2024/GB
 - dates retrieved: 15
 - dates including global indicator: 15

Date       Name                   Global CountryCode Counties
----       ----                   ------ ----------- --------
2024-01-01 New Year`s Day          False GB          ENG, NIR, SCT, WLS
2024-01-02 2 January               False GB          SCT
2024-03-18 Saint Patrick`s Day     False GB          NIR
2024-03-29 Good Friday              True GB
2024-04-01 Easter Monday           False GB          ENG, NIR, WLS
2024-05-06 Early May Bank Holiday   True GB
2024-05-27 Spring Bank Holiday      True GB
2024-07-12 Battle of the Boyne     False GB          NIR
2024-08-05 Summer Bank Holiday     False GB          SCT
2024-08-26 Summer Bank Holiday     False GB          ENG, NIR, WLS
2024-12-02 Saint Andrew`s Day      False GB          SCT
2024-12-25 Christmas Day            True GB
2024-12-26 St. Stephen`s Day        True GB
```

Now scope it to England only, and compare the count:

```powershell
Get-PublicHolidays -CountryCode GB -Region ENG | ft

Fetching holidays from URL: https://date.nager.at/api/v3/PublicHolidays/2024/GB
 - dates retrieved: 15
 - dates including global indicator: 15
 - dates including region filtering: 8    <==== IS THIS WHAT YOU EXPECT?

Date       Name                   Global CountryCode Counties
----       ----                   ------ ----------- --------
2024-01-01 New Year`s Day          False GB          ENG, WLS
2024-03-29 Good Friday              True GB
2024-04-01 Easter Monday           False GB          ENG, NIR, WLS
2024-05-06 Early May Bank Holiday   True GB
2024-05-27 Spring Bank Holiday      True GB
2024-08-26 Summer Bank Holiday     False GB          ENG, NIR, WLS
2024-12-25 Christmas Day            True GB
2024-12-26 St. Stephen`s Day        True GB
```

## Replacing all dates in a schedule

```powershell
Update-TeamsPublicHolidays -ScheduleName 'English Holidays' -CountryCode 'GB' -Region 'ENG' -Year '2025' -Replace
```

> **Note:** as of the current release, the `-Replace` code path is a documented placeholder (it logs a message rather than clearing and rewriting the schedule) - see the [FAQ](faq.md) for what to do instead today.

## Pruning past dates

```powershell
Prune-TeamsPublicHolidays -ScheduleName 'UK National Holidays'

CURRENT DATES:

Start               End
-----               ---
18/06/2024 00:00:00 19/06/2024 00:00:00             <======== THIS IS AN OLD RECORD
25/12/2024 00:00:00 26/12/2024 00:00:00
26/12/2024 00:00:00 27/12/2024 00:00:00


REMAINING DATES AFTER PRUNING:

Start               End
-----               ---
25/12/2024 00:00:00 26/12/2024 00:00:00
26/12/2024 00:00:00 27/12/2024 00:00:00
```

## Running the multi-customer pipeline for one customer

Given this entry in `customers.json`:

```json
{
  "name": "contoso",
  "displayName": "Contoso Ltd",
  "scheduleName": "Contoso UK Holidays",
  "countryCode": "GB",
  "region": "ENG"
}
```

Triggering **Actions > Sync Customer Public Holidays > Run workflow** with `customer: contoso` and `year` left blank will:

1. Resolve the year to next calendar year (e.g. 2027, if run during 2026).
2. Filter `customers.json` down to just the `contoso` entry.
3. Run the `sync` job scoped to the `contoso` GitHub Environment, authenticating to Contoso's own tenant and updating `Contoso UK Holidays` for 2027.

Setting `year: 2028` instead would process 2028 for Contoso specifically, regardless of what year it currently is. Leaving `customer` blank runs the same process for every entry in `customers.json`, each in its own isolated job. See [Automation & Pipelines](automation.md) for the full mechanics.
