
$subscriptionName = "Azure subscription 1"  
$tenantId = "859ec476-c375-44b1-9702-f5980c7de89e"  
$resourceGroupName = "octacerResourceGroup_1"  
$locations = @("Central India", "South India", "West India", "UAE North", "East Asia", "Southeast Asia", "Japan West", "Japan East", "Australia East", "Australia Southeast", "West Europe", "North Europe", "Canada Central", "Canada East", "East US", "East US 2", "West US", "West US 2", "South Central US", "North Central US", "Central US", "West Central US", "West US 3") 
$appServicePlanName = "OctacerAppServicePlan" 
$webAppName = "octacerDemoApp-1"              
$runtime = "dotnet:8"                   
$publishPath = "./publish"                    
$zipFilePath = "./app.zip"                    


Write-Output "Disabling subscription selector for compatibility..."
az config set core.login_experience_v2=off


Write-Output "Logging into Azure..."
$loginOutput = az login --tenant "$tenantId" --output json 2>&1

if ($LASTEXITCODE -eq 0) {

    Write-Output "Login successful. Proceeding with the next steps..."

    
    Write-Output "Setting subscription to '$subscriptionName'..."
    $subscriptionSet = az account set --subscription "$subscriptionName" 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Output "Failed to set subscription. Exiting program."
        Write-Output "Error Details: $subscriptionSet"
        exit 1
    }

    
    Write-Output "Checking if resource group '$resourceGroupName' exists..."
    $resourceGroup = az group show --name "$resourceGroupName" --query "name" --output tsv 2>$null

    if ($resourceGroup) {
        Write-Output "Resource group '$resourceGroupName' already exists."
    } else {
        Write-Output "Resource group '$resourceGroupName' does not exist. Creating it now..."
        $createGroupOutput = az group create --name "$resourceGroupName" --location "$($locations[0])" 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Output "Failed to create resource group. Exiting program."
            Write-Output "Error Details: $createGroupOutput"
            exit 1
        }
        Write-Output "Resource group '$resourceGroupName' created successfully in location '$($locations[0])'."
    }

    
    Write-Output "Checking if App Service Plan '$appServicePlanName' exists..."
    $appServicePlan = az appservice plan show --name "$appServicePlanName" --resource-group "$resourceGroupName" --query "name" --output tsv 2>$null

    if ($appServicePlan) {
        Write-Output "App Service Plan '$appServicePlanName' already exists."
    } else {
        Write-Output "App Service Plan '$appServicePlanName' does not exist. Attempting to create it..."
        $appServicePlanCreated = $false

        foreach ($location in $locations) {
            Write-Output "Trying location: $location"
            $createAppPlanOutput = az appservice plan create --name "$appServicePlanName" --resource-group "$resourceGroupName" --location "$location" --sku F1 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Output "App Service Plan '$appServicePlanName' created successfully in location '$location'."
                $appServicePlanCreated = $true
                break
            } else {
                Write-Output "Failed to create App Service Plan in location '$location'. Trying next location..."
                Write-Output "Error Details: $createAppPlanOutput"
            }
        }

        if (-not $appServicePlanCreated) {
            Write-Output "Failed to create App Service Plan in all specified locations. Exiting program."
            exit 1
        }
    }

    
    Write-Output "Checking if Web App '$webAppName' exists..."
    $webApp = az webapp show --name "$webAppName" --resource-group "$resourceGroupName" --query "name" --output tsv 2>$null

    if ($webApp) {
        Write-Output "Web App '$webAppName' already exists."
    } else {
        Write-Output "Web App '$webAppName' does not exist. Creating it now..."
        $createWebAppOutput = az webapp create --name "$webAppName" --resource-group "$resourceGroupName" --plan "$appServicePlanName" --runtime "$runtime" 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Output "Failed to create Web App. Exiting program."
            Write-Output "Error Details: $createWebAppOutput"
            exit 1
        }
        Write-Output "Web App '$webAppName' created successfully with runtime '$runtime'."
    }

    
    Write-Output "Publishing the ASP.NET Core Web App..."
    dotnet publish -c Release -o "$publishPath"

    if ($LASTEXITCODE -ne 0) {
        Write-Output "Failed to publish the Web App. Exiting program."
        exit 1
    }

    
    Write-Output "Creating ZIP file for deployment..."
    Compress-Archive -Path "$publishPath/*" -DestinationPath "$zipFilePath" -Force

    if ($LASTEXITCODE -ne 0) {
        Write-Output "Failed to create ZIP file. Exiting program."
        exit 1
    }

    
    Write-Output "Deploying ZIP file to Azure Web App..."
    $deployZipOutput = az webapp deploy --resource-group "$resourceGroupName" --name "$webAppName" --src-path "$zipFilePath" --type zip 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Output "Failed to deploy ZIP file to Web App. Exiting program."
        Write-Output "Error Details: $deployZipOutput"
        exit 1
    }
    Write-Output "ZIP file deployed successfully to Web App '$webAppName'."

    
    Write-Output "Re-enabling subscription selector..."
    az config set core.login_experience_v2=on
} else {
    Write-Output "Login failed. Please check your tenant ID and credentials."
    Write-Output "Error Details: $loginOutput"
    exit 1
}
