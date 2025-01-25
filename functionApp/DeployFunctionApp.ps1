# Variables
$functionappName = "NodemmdToPng"
$tenantId = "859ec476-c375-44b1-9702-f5980c7de89e"
$resourceGroupName = "octacerResourceGroup_1"
$location = "EastUS"
$storageAccountName = "octacerstorage1"

# Login to Azure using the tenant ID
Write-Host "Logging in with tenant ID $tenantId..."
$loginResult = az login --tenant $tenantId --output none 2>&1
if ($loginResult -ne $null) {
    Write-Error "Login failed. Exiting program."
    exit 1
}

Write-Host "Login successful. Proceeding to check for Function App existence..."

# Check if Function App exists
$functionAppExists = az functionapp show --name $functionappName --resource-group $resourceGroupName --query "name" --output tsv 2>&1
if ($functionAppExists -eq $null) {
    Write-Host "Function App does not exist. Proceeding to create it..."
    $createFunctionAppResult = az functionapp create `
        --resource-group $resourceGroupName `
        --consumption-plan-location $location `
        --runtime node `
        --runtime-version 20 `
        --functions-version 4 `
        --name $functionappName `
        --storage-account $storageAccountName `
        --os-type Linux

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create Function App. Exiting program."
        exit 1
    } else {
        Write-Host "Function App created successfully."
    }
} else {
    Write-Host "Function App already exists. Proceeding to the next step..."
}

# Publish the Function App
Write-Host "Publishing the Function App..."
$publishResult = func azure functionapp publish $functionappName
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to publish Function App. Exiting program."
    exit 1
}

Write-Host "Function App published successfully."
