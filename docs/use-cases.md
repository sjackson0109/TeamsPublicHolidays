---
title: Use Cases
---

[Home](index.md) · [Background](background.md) · [Use Cases](use-cases.md) · [Automation & Pipelines](automation.md) · [Examples](examples.md) · [FAQ](faq.md)

# Use Cases

## 1. Keeping a single tenant's holiday schedule current

The simplest case: one organisation, one Microsoft 365 tenant, one or more auto-attendants that need to route to an out-of-hours greeting on public holidays. Run `New-TeamsPublicHolidays` once to create the schedule, then `Update-TeamsPublicHolidays` each year (or on a schedule) to keep it current. See [Examples](examples.md).

## 2. One schedule, many call flows

A single `CsOnlineSchedule` can be referenced by any number of auto-attendants and call queues. Rather than maintaining holiday dates separately for every call flow, point them all at one schedule (e.g. `UK National Holidays`) and update it in one place - every call flow that references it inherits the change immediately.

## 3. Regional variation within one country

Public holidays frequently differ by region: Bavaria observes holidays the rest of Germany doesn't; Scotland's bank holidays differ from England, Wales, and Northern Ireland's. The `-Region` parameter on `Get-PublicHolidays` / `New-TeamsPublicHolidays` / `Update-TeamsPublicHolidays` filters the holiday set to national (`Global`) holidays plus only the ones relevant to the specified region, so a Bavaria-specific schedule doesn't pick up holidays that only apply to, say, Saxony.

## 4. Annual maintenance without manual intervention

Public holiday schedules need refreshing every year, and it's easy to let this slip. Instead of relying on someone remembering to run the update in December, the [Automation & Pipelines](automation.md) workflow runs on a schedule (1 December) and prepares *next* year's schedule automatically, well ahead of when it's needed - see the [FAQ](faq.md) for exactly which year gets processed and why.

## 5. Correcting or backfilling a specific year

Sometimes you need to process a year other than "next year" - re-running a year where holidays changed after the fact, preparing a schedule further in advance, or fixing a mistake. The pipeline's `workflow_dispatch` trigger accepts an explicit `year` input for exactly this, validated to be a sensible 4-digit year before anything runs.

## 6. Managed Service Providers supporting many customer tenants

This is the use case the [Automation & Pipelines](automation.md) work was built for: an MSP, IT consultancy, or internal platform team responsible for Teams Voice across *many* separate customer Microsoft 365 tenants, each with its own auto-attendants, its own regional holiday requirements, and - critically - its own security boundary.

Rather than an engineer manually running `Connect-MicrosoftTeams` against each customer tenant in turn (the original, fully manual pattern this project started from), the pipeline:

- Reads a simple manifest (`customers.json`) listing every customer and their holiday configuration (country, region, schedule name).
- Authenticates to each customer's own Entra ID tenant using an app-only certificate registered in that tenant - no interactive sign-in, no shared credential.
- Keeps every customer's tenant ID, application ID, and certificate isolated in a GitHub Environment named after that customer, so one customer's pipeline run can never see another's secrets.
- Can be run for every customer on a schedule, or for a single named customer on demand.

## 7. Keeping schedules lean

Old holiday date ranges left in a schedule don't do anything useful and make the schedule slower for Teams to evaluate and harder for a human to read. `Prune-TeamsPublicHolidays` (and the automatic pruning built into `New-`/`Update-TeamsPublicHolidays`) removes date ranges that have already ended, so schedules stay small and relevant.
