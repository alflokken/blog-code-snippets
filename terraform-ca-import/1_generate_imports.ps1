<#
  .SYNOPSIS
  Generates a Terraform import file for Conditional Access Policies and Named Locations in Azure AD.

  .DESCRIPTION
  This script retrieves Conditional Access Policies and Named Locations from Microsoft Graph and generates a Terraform import file (`imports.tf`) that can be used to import these resources into Terraform state.

  Requirements:
  - Microsoft.Graph.Authentication
  - Policy.Read.All permissions
#>

# Retrieve tenant_id from providers.tf
$tenantId = ((Get-Content .\providers.tf | Where-Object { $_ -match "tenant_id" }) -split '"')[1]

# Ensure Graph Connection with required scope
$mgContext = Get-MgContext
if (-not $mgContext -or
    ($mgContext.TenantId -ne $tenantId) -or
    ("Policy.Read.All" | Where-Object { $_ -notin $mgContext.scopes }).Count
) { Connect-MgGraph -TenantId $tenantDomain -Scopes "Policy.Read.All" -NoWelcome -ErrorAction Stop -Debug:$false }

$graphData = @()
"namedLocations","policies" | ForEach-Object {
    $graphData += Invoke-GraphRequest -Uri "v1.0/identity/conditionalAccess/$_/`?select=id,displayName" -OutputType PSObject
}

$content = @()
foreach ( $query in $graphData ) {

  if ( $query.'@odata.context' -match "namedLocations" ) { 
    $identifierType = "namedLocations"
    $destinationType = "named_location"
  }
  else { 
    $identifierType = "policies"
    $destinationType = "conditional_access_policy"
  }

  # terraform import code block formatting
  foreach ( $object in $query.value ) {
    $content += "import {"
    $content += "    id = `"identity/conditionalAccess/$identifierType/$($object.id)`""
    $content += "    to = azuread_$destinationType.$($object.displayName -replace '\s', '_' -replace '\W')"
    $content += "}"
  }
}
$content | Out-File "imports.tf" -Encoding utf8 -Force