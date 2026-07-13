<#
.SYNOPSIS
    CI entry point: authenticates to a single customer's Microsoft 365 tenant using an
    app-only certificate, then creates or updates that customer's Teams holiday schedule.

.DESCRIPTION
    Designed to run non-interactively from a GitHub Actions job scoped to a per-customer
    GitHub Environment (see .github/workflows/sync-customer-holidays.yml). Tenant/app
    identity is read from environment variables so that each customer's credentials stay
    isolated to that customer's Environment secrets and variables, and are never shared
    with any other customer's pipeline run.

.NOTES
    Required environment variables (populated from the calling job's GitHub Environment):
        AZURE_TENANT_ID             Customer's Entra ID tenant ID                (Environment variable)
        AZURE_CLIENT_ID             App registration (application) ID           (Environment variable)
        AZURE_CERTIFICATE_BASE64    Base64-encoded PFX for the app's cert credential (Environment secret)
        AZURE_CERTIFICATE_PASSWORD  Password protecting the PFX, blank if none  (Environment secret)

    The app registration must have certificate-based, app-only access granted (and admin
    consented) in the customer's tenant for the Microsoft Teams cmdlets used here.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$CustomerName,

    [Parameter(Mandatory)]
    [string]$ScheduleName,

    [string]$CountryCode = "GB",
    [string]$Region = "",
    [int]$Year = (Get-Date).Year
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "TeamsPublicHolidays.ps1")

foreach ($required in @('AZURE_TENANT_ID', 'AZURE_CLIENT_ID', 'AZURE_CERTIFICATE_BASE64')) {
    if (-not (Get-Item "env:$required" -ErrorAction SilentlyContinue)) {
        throw "Missing required environment variable '$required' for customer '$CustomerName'. Check that the GitHub Environment named '$CustomerName' defines it."
    }
}

$tenantId = $env:AZURE_TENANT_ID
$clientId = $env:AZURE_CLIENT_ID
$certBytes = [Convert]::FromBase64String($env:AZURE_CERTIFICATE_BASE64)
$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
    $certBytes, $env:AZURE_CERTIFICATE_PASSWORD, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
)

$store = [System.Security.Cryptography.X509Certificates.X509Store]::new("My", "CurrentUser")
$store.Open("ReadWrite")
$store.Add($cert)
$store.Close()

try {
    Write-Host "Authenticating to customer '$CustomerName' (tenant $tenantId) using app-only certificate auth..."
    Connect-MicrosoftTeams -TenantId $tenantId -ApplicationId $clientId -CertificateThumbprint $cert.Thumbprint | Out-Null

    Write-Host "Processing schedule '$ScheduleName' for customer '$CustomerName' - year $Year (country $CountryCode, region $Region)"

    $existingSchedule = Get-CsOnlineSchedule | Where-Object { $_.Name -eq $ScheduleName }
    if ($null -eq $existingSchedule) {
        Write-Host "Schedule '$ScheduleName' not found for '$CustomerName' - creating it."
        New-TeamsPublicHolidays -ScheduleName $ScheduleName -CountryCode $CountryCode -Region $Region -Year $Year
    } else {
        Write-Host "Schedule '$ScheduleName' found for '$CustomerName' - updating it."
        Update-TeamsPublicHolidays -ScheduleName $ScheduleName -CountryCode $CountryCode -Region $Region -Year $Year
    }
} finally {
    try { Disconnect-MicrosoftTeams -Confirm:$false | Out-Null } catch {}

    $store.Open("ReadWrite")
    $store.Remove($cert)
    $store.Close()
}
