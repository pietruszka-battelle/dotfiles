#!/usr/bin/env -S powershell.exe -ExecutionPolicy Bypass

param(
    [Parameter(Mandatory)]
    [String]$Workload,
    [Parameter(Mandatory)]
    [String]$WhitelistDomains
)

$domains = [Array]($WhitelistDomains -split ",")
$exchangeEnvironmentName = "O365USGovGCCHigh"

function add-inbound-whitelist {
  param (
    [string[]]$Workload,
    [string[]]$domain
  )

  if (Get-TransportRule | where {$_.name -eq "Inbound Domain Allow - $Workload - $domain"}) {
    Write-Host "$Workload - $domain Rule already exists, skipping..."
  } else {
    New-TransportRule -Name "Inbound Domain Allow - $Workload - $domain" -SentToMemberOf cube-$Workload-users@battelle.us -SenderDomainIs $domain -StopRuleProcessing $true -SetAuditSeverity "Low" -Comments "Inbound Domain Allow List for $Workload" -Priority 2 -SetSCL 0 -SetHeaderName "X-ETR" -SetHeaderValue "Set SCL=0 for domain allow list" | Out-Null
  }
}

function add-outbound-whitelist {
  param (
    [string[]]$Workload,
    [string[]]$domain
  )

  if (Get-TransportRule | where {$_.name -eq "Outbound Domain Allow - $Workload - $domain"}) {
    Write-Host "$Workload - $domain Rule already exists, skipping..."
  } else {
    New-TransportRule -Name "Outbound Domain Allow - $Workload - $domain" -FromMemberOf cube-$Workload-users@battelle.us -RecipientDomainIs $domain -StopRuleProcessing $true -SetAuditSeverity "Low" -Comments "Outbound Domain Allow List for $Workload" -Priority 3 -SetSCL 0 -SetHeaderName "X-ETR" -SetHeaderValue "Set SCL=0 for domain allow list" | Out-Null
  }
}

Write-Host "---> Connecting to Exchange Online"
try {
  Connect-ExchangeOnline -ExchangeEnvironmentName $exchangeEnvironmentName -ShowBanner:$FALSE
}
catch { "ERROR: Could not connect to Exchange Online" }

Write-Host "Domain name: $((Get-AcceptedDomain | Where-Object { $PSItem.Default }).DomainName)"

Write-Host "---> Add rules to the workload"
for ($i=0; $i -lt $domains.Count; $i++) {
  add-inbound-whitelist -Workload $Workload -domain $domains[$i]
  add-outbound-whitelist -Workload $Workload -domain $domains[$i]
}

Write-Host "---> Disconnecting from Exchange Online"
Disconnect-ExchangeOnline -Confirm:$FALSE -InformationAction Ignore -ErrorAction SilentlyContinue
