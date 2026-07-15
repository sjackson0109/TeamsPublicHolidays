---
title: Automation & Pipelines
---

[Home](index.md) · [Background](background.md) · [Use Cases](use-cases.md) · [Automation & Pipelines](automation.md) · [Examples](examples.md) · [FAQ](faq.md)

# Automation & Pipelines

This page is a deep dive into `.github/workflows/sync-customer-holidays.yml` - the GitHub Actions pipeline that runs the toolkit unattended against many customer tenants. For the onboarding checklist, see the [README](https://github.com/sjackson0109/TeamsPublicHolidays#multi-customer-automation-github-actions); this page covers the *why* and the mechanics in more depth.

## The problem it solves

Running `Connect-MicrosoftTeams` interactively works fine for one tenant, but doesn't scale to supporting many customer tenants, and doesn't isolate credentials from each other if you try to script it naively (one shared secret, or secrets sitting in the same scope, means a bug or a compromise in one customer's run can expose another's). The pipeline is built around two ideas:

1. **App-only authentication per customer**, so no interactive sign-in and no shared identity is used across tenants.
2. **Per-customer GitHub Environments**, so GitHub itself enforces that a job only ever sees the secrets belonging to the customer it's processing.

## Architecture

```
customers.json  ──►  discover job  ──►  matrix (one entry per customer)
                        │
                        ├─ resolve-year: works out which calendar year to process
                        └─ set-matrix: filters customers.json (optionally to one customer)
                                │
                                ▼
                       sync job (one per matrix entry)
                       environment: <customer name>   ◄── scopes secrets/vars to this customer only
                                │
                                ▼
                 Sync-CustomerHolidays.ps1
                   1. import cert from AZURE_CERTIFICATE_BASE64 (Environment secret)
                   2. Connect-MicrosoftTeams -TenantId -ApplicationId -CertificateThumbprint
                   3. New-/Update-TeamsPublicHolidays for that customer's schedule
                   4. disconnect, remove cert from the runner's cert store
```

The `discover` job runs once and produces two outputs consumed by every customer's `sync` job: the resolved `year`, and a JSON matrix built from `customers.json` (optionally filtered to a single customer via the `customer` input). The `sync` job then fans out, one job per customer, with `fail-fast: false` so one customer's failure doesn't stop the others from running.

## Why certificate-based app-only auth

The pipeline authenticates using a certificate credential on an Entra ID app registration, rather than a client secret or an interactive login:

- **No interactive session** - a service can't click through an MFA prompt, so app-only auth is required for unattended automation.
- **No shared identity across customers** - each customer has their own app registration, in their own tenant, so there is no single credential whose compromise affects every customer at once.
- **Stronger than a client secret** - a certificate's private key never needs to be transmitted to Microsoft during authentication (unlike a client secret, which is sent on every token request), and certificates are generally easier to constrain and audit.

`Sync-CustomerHolidays.ps1` imports the certificate from a base64-encoded secret into the runner's ephemeral certificate store for the duration of the job, authenticates, and removes it again in a `finally` block - the certificate never persists beyond a single job run.

## Why per-customer GitHub Environments

A [GitHub Environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) is a named scope that a job can opt into via `environment: <name>`. Secrets and variables defined on an Environment are only exposed to jobs that declare that Environment - jobs for a different Environment (or no Environment) cannot see them.

By naming each customer's Environment after that customer's `name` in `customers.json`, and setting `environment: ${{ matrix.name }}` on the `sync` job, GitHub enforces the isolation structurally: there's no code path in the workflow that could accidentally read `contoso`'s certificate while processing `fabrikam`. This also means:

- Environments can carry their own protection rules (required reviewers, deployment branch restrictions) if you want a human gate before a sync runs against a particular customer.
- Revoking a customer's access is a matter of deleting their Environment and app registration - it doesn't require touching any other customer's configuration.

## What lives where

| Data | Location | Secret? |
|---|---|---|
| Customer routing info (`name`, `scheduleName`, `countryCode`, `region`) | `customers.json` in the repo | No |
| Tenant ID, Application (client) ID | The customer's GitHub Environment, as **variables** (`vars.AZURE_TENANT_ID`, `vars.AZURE_CLIENT_ID`) | No, but scoped |
| Certificate (base64 PFX) and its password | The customer's GitHub Environment, as **secrets** (`secrets.AZURE_CERTIFICATE_BASE64`, `secrets.AZURE_CERTIFICATE_PASSWORD`) | Yes |

`customers.json` is intentionally not secret - it's just a routing table. Nothing in it would help an attacker without also having access to the matching customer's GitHub Environment secrets.

## Triggers and year resolution

The workflow has two triggers:

- **`schedule`**: `0 3 1 12 *` - 03:00 UTC on 1 December every year.
- **`workflow_dispatch`**: manual, with two optional inputs - `customer` (limit the run to one customer) and `year` (process a specific year).

A dedicated `resolve-year` step works out which year to process, and validates it before any customer's credentials are touched:

- On a scheduled run, or a manual run with `year` left blank, the resolved year is always **next calendar year** - a run on 1 December 2026 prepares **2027**. This is deliberate: the point of running in early December is to have the following year's schedule ready well in advance, not to patch the current year.
- On a manual run with `year` supplied, it's validated as a 4-digit integer between 2000 and 2100, and used exactly as given - useful for backfilling or correcting a specific year.

The resolved year is written to the workflow log (`Write-Host`) and to the GitHub Actions job summary, both once for the whole run and again per customer, so it's easy to confirm at a glance which year a given run actually processed.

## Onboarding checklist

The step-by-step onboarding process (registering an app, uploading a certificate, granting consent, creating the GitHub Environment, adding secrets/variables, and adding a `customers.json` entry) is documented in the [README's "Multi-Customer Automation" section](https://github.com/sjackson0109/TeamsPublicHolidays#multi-customer-automation-github-actions) to keep it next to the code it describes.
