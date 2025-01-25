# Variables
$resourceGroupName = "octacerResourceGroup_1"
$storageAccountName = "octacerstorage1"
$location = "eastus"
$skuName = "Standard_LRS"
$kind = "StorageV2"
$tenantId = "859ec476-c375-44b1-9702-f5980c7de89e"
$containerName = "teststoragecontainer"
$localFolderPath = "D:\web\AzureTestApp\wwwroot"

# Ensure Azure CLI is logged in
Write-Output "Ensuring Azure CLI login status..."
$loginStatus = az account show --query "id" -o tsv 2>&1
if ($loginStatus -match "Please run 'az login'") {
    Write-Output "Azure CLI not logged in. Logging in with Tenant ID '$tenantId'..."
    az login --tenant $tenantId --output none
    if (-not $?) {
        Write-Error "Failed to log in to Azure CLI. Exiting..."
        exit 1
    }
} else {
    Write-Output "Azure CLI is already logged in."
}

# Retrieve subscription for validation
Write-Output "Retrieving available subscriptions..."
$subscriptions = az account list --query "[].{Name:name, ID:id}" -o table
Write-Output $subscriptions

# Validate and set the subscription
$subscriptionId = az account list --query "[?tenantId=='$tenantId' && name=='Azure subscription 1'].id" -o tsv
if (-not $subscriptionId) {
    Write-Error "The subscription 'Azure subscription 1' was not found under the tenant. Exiting..."
    exit 1
}

Write-Output "Switching to subscription: $subscriptionId..."
az account set --subscription $subscriptionId
if (-not $?) {
    Write-Error "Failed to switch to subscription '$subscriptionId'. Exiting..."
    exit 1
}

# Check if the storage account exists
Write-Output "Checking if storage account '$storageAccountName' exists in resource group '$resourceGroupName'..."
$storageAccountExists = az storage account check-name --name $storageAccountName --query "nameAvailable" -o tsv

if ($storageAccountExists -eq "false") {
    Write-Output "Storage account '$storageAccountName' already exists."
} else {
    Write-Output "Storage account '$storageAccountName' does not exist. Creating the storage account..."
    az storage account create `
        --name $storageAccountName `
        --resource-group $resourceGroupName `
        --location $location `
        --sku $skuName `
        --kind $kind
    if (-not $?) {
        Write-Error "Failed to create storage account '$storageAccountName'. Exiting..."
        exit 1
    }
    Write-Output "Storage account '$storageAccountName' created successfully."
}

# Retrieve storage account key
Write-Output "Retrieving storage account key for '$storageAccountName'..."
$storageKey = az storage account keys list --account-name $storageAccountName --resource-group $resourceGroupName --query "[0].value" -o tsv

if (-not $storageKey) {
    Write-Error "Failed to retrieve storage account key. Exiting..."
    exit 1
}

# Check if the container exists
Write-Output "Checking if container '$containerName' exists..."
$containerExists = az storage container exists --name $containerName --account-name $storageAccountName --account-key $storageKey --query "exists" -o tsv

if ($containerExists -eq "false") {
    Write-Output "Container '$containerName' does not exist. Creating the container..."
    az storage container create --name $containerName --account-name $storageAccountName --account-key $storageKey
    if (-not $?) {
        Write-Error "Failed to create container '$containerName'. Exiting..."
        exit 1
    }
} else {
    Write-Output "Container '$containerName' already exists."
}

# Upload the folder to Azure Storage
Write-Output "Uploading folder '$localFolderPath' to container '$containerName'..."
az storage blob upload-batch `
    --source $localFolderPath `
    --destination $containerName `
    --account-name $storageAccountName `
    --account-key $storageKey

if ($?) {
    Write-Output "Folder '$localFolderPath' uploaded successfully to container '$containerName'."
} else {
    Write-Error "Failed to upload folder '$localFolderPath'. Exiting..."
    exit 1
}
