# Clean up the generated terraform files and split them into multiple files prefixed by underscore.
$path = "generated.tf"

# removes empty blocks and null values (including sign_in_frequency = 0 (bug in the terraform provider))
$fileContent = Get-Content $path -Encoding UTF8
$fileContent | Where-Object { $_ -notmatch "\[\]$|=\snull$|sign_in_frequency\s+=\s0$" } | Out-File $path -Encoding utf8 -Force

# split the file into multiple files
$fileContent = Get-Content $path -Raw
$resources = $fileContent -split "# __generated__ by Terraform.*\r?\n" | Where-Object { $_ -match "^resource" }

# named locations go in one file
$namedLocationsContent = @()
foreach ( $res in $resources ) {
    # extract the resource type and name from the first line
    $metadata = ($res -split "\r?\n" )[0] -replace "`"" -split "\s"
    $type = $metadata[1]
    $name = $metadata[2]

    if ( $type -match "azuread_conditional_access_policy" ) {  $res | Out-File "$name.tf" -Encoding utf8 -Force }
    elseif ( $type -match "azuread_named_location" ) { $namedLocationsContent += $res }
    else { Write-Warning "Unknown resource type: $type" }
}
$namedLocationsContent | Out-File "_named_locations.tf" -Encoding utf8 -Force

# Fix the formatting
terraform fmt | Out-Null

# remove files that are no longer needed
remove-item $path -Force
remove-item imports.tf -Force