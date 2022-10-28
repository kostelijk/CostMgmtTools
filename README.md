# CostMgmtTools

## Log-RunningVM
This Function app reports on how many VM's per VmSize currently are running. This information is logged to a Log Analytics workspace. This is especially usefull for machines that are dynamically switched on and of. The logging could help in deciding how to purchase an Azure Saving plan. 

Information on how to setup Log Analytics, a Data Collection Endpoint and a Data Collection rule can be found in [Tutorial: Send data to Azure Monitor Logs using REST API (Azure portal)](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal)

The Function App must be configured with a managed identity. 
The managed identity should have read permissions to the subscritpions in scope to be able to collect VM powerstate information.
The Function App Application Settings should contain these additional Application Settings:
- **AzureSubscription_IDs.** A comma seperated list of subscription id's 
- **DceURI.** The URI which is configured during the configuration of the Data Collection Endpoint. [Configure Application](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal#configure-application) 
- **DcrImmutableId.** [Collect information from DCR](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal#collect-information-from-dcr)


