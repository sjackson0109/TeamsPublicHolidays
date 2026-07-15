---
title: Home
---

[Home](index.md) · [Background](background.md) · [Use Cases](use-cases.md) · [Automation & Pipelines](automation.md) · [Examples](examples.md) · [FAQ](faq.md)

# Teams Public Holidays

**Teams Public Holidays** keeps Microsoft Teams Auto-Attendant and Call Queue holiday schedules up to date, automatically, using public holiday data pulled from a free REST API.

Instead of manually typing dates into a `CsOnlineSchedule` every year - and forgetting to do it, or getting a region wrong - this project fetches accurate, region-aware public holiday dates and writes them straight into the schedule your call flows already use.

It works two ways:

- **As a PowerShell toolkit** you run yourself, interactively, against one Microsoft 365 tenant.
- **As a GitHub Actions pipeline** that runs unattended against *many* customer tenants, each authenticated independently and each with its own isolated credentials.

## Why this exists

Anyone who has supported Teams Voice for more than one organisation knows the pattern: every December, someone has to remember to add next year's bank holidays to every auto-attendant's schedule, get the regional variations right, and prune the old dates so the schedule doesn't bloat. It's fiddly, easy to get wrong, and easy to forget. This project turns that into a single command - or a fully automated annual pipeline run. See [Background](background.md) for the full story.

## What it does

- **Fetches holidays dynamically** from [date.nager.at](https://date.nager.at), filtered by country and, where relevant, by region/county (e.g. Bavaria-only holidays in Germany, or Scotland-only holidays in the UK).
- **Creates or updates** a Teams `CsOnlineSchedule` with those dates, so every auto-attendant or call queue pointed at that schedule picks up the change instantly - update one schedule, and every call flow attached to it benefits.
- **Prunes past dates automatically**, so schedules never carry forward holidays that have already happened.
- **Scales to many customers** via a GitHub Actions pipeline that authenticates to each customer's own Entra ID tenant using an app-only certificate, with each customer's secrets isolated in their own GitHub Environment. See [Automation & Pipelines](automation.md).

## Quick start

```powershell
Install-Module MicrosoftTeams
Import-Module MicrosoftTeams
Connect-MicrosoftTeams

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
Import-Module .\TeamsPublicHolidays.ps1

New-TeamsPublicHolidays -ScheduleName 'UK National Holidays' -CountryCode 'GB' -Region 'ENG'
```

See [Examples](examples.md) for more, and [Use Cases](use-cases.md) for the scenarios this project is built around.

## Where to go next

| Page | What's in it |
|---|---|
| [Background](background.md) | Why this project exists, how it evolved, and the design decisions behind it |
| [Use Cases](use-cases.md) | The real scenarios this covers, from a single tenant to a multi-customer MSP practice |
| [Automation & Pipelines](automation.md) | Deep dive into the GitHub Actions multi-customer pipeline, app-only certificate auth, and per-customer GitHub Environments |
| [Examples](examples.md) | Worked examples for every function, with sample output |
| [FAQ](faq.md) | Answers to the questions that come up most |

## Project links

- [Source code and issues](https://github.com/sjackson0109/TeamsPublicHolidays)
- [Changelog](https://github.com/sjackson0109/TeamsPublicHolidays/blob/main/Changelog.md)
- [License](https://github.com/sjackson0109/TeamsPublicHolidays/blob/main/LICENSE)

These docs are built with GitHub Pages from the `/docs` folder. If you're viewing this on GitHub itself rather than as a published site, the maintainer needs to enable Pages under **Settings > Pages > Source: Deploy from a branch > main / docs**.
