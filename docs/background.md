---
title: Background
---

[Home](index.md) · [Background](background.md) · [Use Cases](use-cases.md) · [Automation & Pipelines](automation.md) · [Examples](examples.md) · [FAQ](faq.md)

# Background

## The problem

Microsoft Teams Auto-Attendants and Call Queues support a "holiday schedule" (`CsOnlineSchedule`) - a set of date ranges that trigger out-of-hours call routing. It's a genuinely useful feature: a receptionist doesn't need to remember to flip a switch on Christmas Day, the schedule just knows.

The catch is that Teams doesn't populate that schedule for you. Someone has to know every relevant public holiday, in the right region, for the right year, and type each one in - through the admin center or through PowerShell, one `New-CsOnlineDateTimeRange` at a time. For a single UK organisation that's a dozen or so dates a year. For someone supporting dozens of customer tenants across multiple countries, each with their own regional variations, it becomes a recurring, error-prone chore that's easy to deprioritise until a customer's auto-attendant fails to switch to the holiday greeting.

## The origin

This project started in December 2023 as a single function to keep one UK schedule current, using a hint from [Bjoren Dassow (@dassbj01)](https://github.com/dassbj01) about the [date.nager.at](https://date.nager.at) public holiday API - a free, actively maintained service covering dozens of countries with structured, machine-readable holiday data (including which holidays are nationwide vs. regional).

From there it grew in response to real support work:

- **Germany support** was added within days, because German public holidays vary significantly by federal state (`Land`) - a pattern that repeats in many countries (the UK's home nations, Spain's autonomous communities, and so on).
- **Regional filtering** was added by [Mitchell Bakker (@mitchelljb)](https://github.com/mitchelljb), turning a country-wide holiday list into one correctly scoped to a specific region/county, and cleaning up how that data set is presented.
- **Pruning** was added once it became clear that schedules left to accumulate past dates get harder to read and slower for the Teams service to evaluate - removing stale ranges at source keeps the data set lean.
- **Multi-customer automation** was added most recently, turning what had been a manual, per-tenant PowerShell exercise (documented candidly in the README as being "used on customer tenants that I've had the privilege of supporting") into a GitHub Actions pipeline that can authenticate to and update *any number* of customer tenants unattended, each isolated from the others. See [Automation & Pipelines](automation.md) for how that works.

The full list of changes is in the [Changelog](https://github.com/sjackson0109/TeamsPublicHolidays/blob/main/Changelog.md).

## Design principles

A few decisions run through the whole project:

- **One schedule, many consumers.** A single `CsOnlineSchedule` can be attached to any number of auto-attendants or call queues. The tooling updates one shared table of dates rather than duplicating holiday data per call flow.
- **Data comes from an external source of truth, not a hand-maintained list.** Holiday dates are fetched live from `date.nager.at` rather than hardcoded, so the same tool works for any supported country without code changes - only a country/region code needs to change.
- **Idempotent by default.** Running the update functions again doesn't duplicate dates already present, and past dates are pruned automatically, so the tool is safe to run repeatedly (interactively, or on an annual schedule).
- **Small, composable functions.** `Get-PublicHolidays`, `New-TeamsPublicHolidays`, `Update-TeamsPublicHolidays`, and `Prune-TeamsPublicHolidays` each do one job and can be used independently - which is also what makes them straightforward to wrap in a non-interactive CI script.
- **Credentials never get mixed between customers.** Once the tool needed to run against many customer tenants unattended, the automation was built so that each customer's tenant ID, app ID, and certificate live only in that customer's own GitHub Environment - a pipeline run for one customer structurally cannot see another customer's secrets.

## Who maintains it

This is a small, personally-maintained project by [Simon Jackson (@sjackson0109)](https://github.com/sjackson0109), built out of real support work and shared publicly under an open licence. There's no commercial backing or SLA - see the [FAQ](faq.md) and the project's README for the support expectations.
