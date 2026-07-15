---
title: FAQ
---

[Home](index.md) · [Background](background.md) · [Use Cases](use-cases.md) · [Automation & Pipelines](automation.md) · [Examples](examples.md) · [FAQ](faq.md)

# Frequently Asked Questions

### What does this project actually do?

It fetches public holiday data from [date.nager.at](https://date.nager.at) and writes it into a Microsoft Teams `CsOnlineSchedule`, which any number of Auto-Attendants or Call Queues can reference to trigger out-of-hours call routing on public holidays. See [Background](background.md) and [Use Cases](use-cases.md).

### What is a `CsOnlineSchedule`, exactly?

It's the Teams Voice object that defines a "holiday schedule" or "business hours schedule" - a named set of date/time ranges. Auto-Attendants and Call Queues reference a schedule by name and change their call routing behaviour (e.g. play a holiday greeting) whenever the current time falls inside one of its ranges.

### Do I need Teams Admin rights to use this?

Yes. Interactively, you need whatever role lets you run `Connect-MicrosoftTeams` and manage `CsOnlineSchedule` objects (typically Teams Administrator or a similarly-scoped role). For the automated pipeline, the app registration used for app-only auth needs equivalent application-level permissions granted and admin-consented in the customer's tenant - see [Automation & Pipelines](automation.md).

### What PowerShell version and OS does this need?

The core script (`TeamsPublicHolidays.ps1`) targets PowerShell 3.0 or later with the `MicrosoftTeams` module installed. The `MicrosoftTeams` module itself is REST-based and works cross-platform under PowerShell 7+ (Windows, macOS, Linux), which is also why the GitHub Actions pipeline runs happily on `ubuntu-latest` runners using `pwsh`.

### Where does the holiday data come from, and how accurate is it?

From [date.nager.at](https://date.nager.at), a free, community-maintained public holiday API covering dozens of countries with structured data distinguishing nationwide (`Global`) holidays from region/county-specific ones. It's actively maintained, but like any third-party data source it's worth spot-checking a new country/region the first time you use it (see [Examples](examples.md) for how to preview results with `Get-PublicHolidays` before writing anything to Teams).

### What if my country or region isn't covered by the API?

`Get-PublicHolidays` will return an empty result (and log an error) for a country code the API doesn't recognise. Check the [date.nager.at](https://date.nager.at) documentation for supported countries. There's currently no fallback data source built into this project.

### What's the difference between `New-`, `Update-`, and `Prune-TeamsPublicHolidays`?

- `New-TeamsPublicHolidays` creates a brand-new schedule and populates it with holidays for the given country/region/year.
- `Update-TeamsPublicHolidays` adds any missing holidays to an *existing* schedule (matched by name) without duplicating ones already present, and prunes past dates while it's at it.
- `Prune-TeamsPublicHolidays` only removes past-dated ranges from an existing schedule; it doesn't fetch or add anything new.

### Does `-Replace` on `Update-TeamsPublicHolidays` actually replace the schedule?

Not yet - as of the current release, the `-Replace` switch is a documented placeholder in the code; it logs a message rather than clearing and rewriting the schedule's dates. If you need to fully replace a schedule's contents today, delete the existing `CsOnlineSchedule` and recreate it with `New-TeamsPublicHolidays`, or open an issue if you'd like to help implement `-Replace` properly.

### Why are past holidays automatically removed?

Two reasons: date ranges that have already ended serve no purpose in a holiday schedule, and Teams has to evaluate every range in a schedule at call time - keeping the data set lean keeps that evaluation fast and the schedule easy for a human to read. See [Background](background.md#design-principles).

### Can one holiday schedule serve multiple auto-attendants?

Yes, and this is one of the main efficiency wins of the project - see [Use Cases](use-cases.md#2-one-schedule-many-call-flows). Point every auto-attendant/call queue that shares the same holiday calendar at the same schedule name, and update that one schedule.

### How does the multi-customer pipeline work, in short?

A GitHub Actions workflow reads `customers.json`, and for each customer authenticates to that customer's own Entra ID tenant using an app-only certificate, then runs the same `New-`/`Update-TeamsPublicHolidays` logic against that customer's schedule - all inside a job scoped to a GitHub Environment named after the customer, so credentials never cross between customers. Full detail on [Automation & Pipelines](automation.md).

### Why certificate auth instead of a client secret, for the pipeline?

A certificate's private key is never transmitted to Microsoft during authentication, unlike a client secret which is sent on every token request - and certificates are generally easier to scope, rotate, and audit per app registration. See [Automation & Pipelines](automation.md#why-certificate-based-app-only-auth).

### Where are a customer's secrets actually stored?

In that customer's GitHub Environment (Settings > Environments in this repository), as Environment secrets (`AZURE_CERTIFICATE_BASE64`, `AZURE_CERTIFICATE_PASSWORD`) and Environment variables (`AZURE_TENANT_ID`, `AZURE_CLIENT_ID`). `customers.json` in the repo itself holds no secrets - only non-sensitive routing information (customer name, schedule name, country/region).

### How is one customer's pipeline run kept from seeing another customer's secrets?

The `sync` job in the workflow sets `environment: ${{ matrix.name }}`, and GitHub Environments only expose their secrets/variables to jobs that declare that specific Environment. There's no shared credential or shared scope a bug could leak across - the isolation is enforced by GitHub itself, not by application logic. See [Automation & Pipelines](automation.md#why-per-customer-github-environments).

### What Microsoft Teams/Graph permissions does the app registration need?

This depends on which cmdlets you rely on and can change as Microsoft evolves app-only support for Teams PowerShell, so check current Microsoft documentation before granting permissions. At minimum you'll need the application permissions required for the `CsOnlineSchedule` cmdlets, admin-consented in the customer's tenant; some environments additionally require `New-CsApplicationAccessPolicy` / `Grant-CsApplicationAccessPolicy` to scope the app's access to specific resource accounts.

### When does the scheduled pipeline run, and which year does it process?

It runs at 03:00 UTC on 1 December every year, and always processes **next** calendar year - a run on 1 December 2026 prepares 2027, not 2026. This is deliberate, so the following year's schedule is in place well in advance. See [Automation & Pipelines](automation.md#triggers-and-year-resolution).

### Can I run the pipeline manually for a specific year?

Yes - trigger it via `workflow_dispatch` and set the `year` input to any 4-digit year between 2000 and 2100. Leaving it blank defaults to next calendar year, matching the scheduled behaviour. An out-of-range or malformed year fails the run immediately with a clear error, before any customer's credentials are touched.

### What happens if I run the workflow for a customer name that isn't in `customers.json`?

The `discover` job's matrix-building step fails fast with an explicit error ("No matching customers found...") before any authentication is attempted, rather than silently doing nothing.

### Is there a cost to running this via GitHub Actions?

Only the normal GitHub Actions compute minutes for your plan/repo visibility (public repositories on GitHub.com currently get free Actions minutes; private repositories draw from your account's included minutes or billed usage). The workflow itself is lightweight - a short-lived job per customer, once a year plus however often you trigger it manually.

### How do I rotate a customer's certificate before it expires?

Generate a new certificate, upload its public key to the same app registration (or a new one), and update that customer's `AZURE_CERTIFICATE_BASE64` / `AZURE_CERTIFICATE_PASSWORD` Environment secrets with the new `.pfx`. No code or workflow changes are needed - the pipeline just reads whatever is currently in the Environment.

### How do I decommission a customer?

Remove their entry from `customers.json` and delete their GitHub Environment (and, in their tenant, the app registration and certificate) once you're done. There's nothing else in the codebase that references a specific customer.

### Is this project officially supported by Microsoft, or by the maintainer as a commercial product?

No to both. It's an independent, openly-licensed project built by [Simon Jackson (@sjackson0109)](https://github.com/sjackson0109) out of real Teams Voice support work, provided as-is with no warranty or guaranteed support - see the project [README](https://github.com/sjackson0109/TeamsPublicHolidays#support-or-warranty).

### I found a bug, or want to suggest a feature - what do I do?

Open an issue (or a discussion, for a more open-ended idea) on the [GitHub repository](https://github.com/sjackson0109/TeamsPublicHolidays/issues). Feedback and bug reports are genuinely useful even though there's no formal support commitment.
