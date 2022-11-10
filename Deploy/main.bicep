targetScope='subscription'

// Parameters for Resource Group creation
@description('Target resource group')
param resourceGroupName string

@description('Region (location)')
param resourceGroupLocation string

// Parameters for calling main module
@description('The name of the function app that you wish to create.')
param appName string

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Log Analytics Workspace name')
param laName string

@description('Log Analytics Resource Group name')
param laResourceGroup string

@description('Log Analytics Workspace ID')
param workspaceId string

@description('Custom Table Name (without _CL)')
param customTableName string = 'RunningVMs'

@description('AzureSubscription IDs is a comma separated list')
param azureSubscriptionIDs string


resource FunctionAppRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

resource LogAnalyticsRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: laResourceGroup
  location: resourceGroupLocation
}

module customTable 'customtable.bicep' = {
  name: 'customTable'
  scope: LogAnalyticsRG
  params:{
    laName: laName
    customTableName: customTableName
  }
}

module functionappDeployment 'functionappdeployment.bicep' = {
  name: 'functionappDeployment'
  scope: FunctionAppRG
  params:{
    appName: appName
    storageAccountType: storageAccountType
    location: resourceGroupLocation
    laName: laName
    laResourceGroup: laResourceGroup
    workspaceId: workspaceId
    customTableName: customTableName
    azureSubscriptionIDs: azureSubscriptionIDs
  }
}

output dceURI string = functionappDeployment.outputs.dceURI
output dcrImmutableId string = functionappDeployment.outputs.dcrImmutableId
output functionAppName string = functionappDeployment.outputs.functionAppName
output principalId string = functionappDeployment.outputs.principalId
