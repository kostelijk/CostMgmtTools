# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

################################################## Sample Script ###########################################################

$DceURI = $env:DceURI
$DcrImmutableId = $env:DcrImmutableId
$Table = "RunningVMs_CL"

# Function App needs to logon with MI to be able to query subscriptions
Connect-AzAccount -Identity

# Get Bearer token
$resourceURI = "https://monitor.azure.com/"
$accessToken = get-azaccesstoken -ResourceUrl $resourceURI

#$subscriptions = Get-AzSubscription
$subscriptions = ($env:AzureSubscription_IDs).split(',')

$runningVMs = @()

foreach($subscription in $subscriptions){

    #Set-AzContext -subscriptionId $subscription.Id
    Set-AzContext -subscriptionId $subscription

    $runningVMs += get-azvm -Status|where-object PowerState -eq "VM Running"

    # Pricing info: https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices
    #$vmSize = (Invoke-WebRequest -Uri "https://prices.azure.com/api/retail/prices?api-version=2021-10-01-preview&currencyCode='EUR'&`$filter=serviceName eq 'Virtual Machines' and armSkuName eq 'Standard_B2s' and armRegionName eq 'westeurope'").Content|ConvertFrom-Json
}

    if($runningVMs){
        $runningVMs = $runningVMs|Select-Object -Property * -ExpandProperty HardwareProfile|Group-Object VmSize|Select-Object -Property Name, Count
        ## Generate and send some data
        foreach ($runningVM in $runningVMs) {
            # We are going to send log entries one by one with a small delay
            $log_entry = @{
                # Define the structure of log entry, as it will be sent
                TimeGenerated = Get-Date ([datetime]::UtcNow) -Format O
                Application = "LogGenerator"
                VmSize = $runningVM.Name
                Value = $runningVM.Count
            }
            # Sending the data to Log Analytics via the DCR!
            $body = $log_entry | ConvertTo-Json -AsArray;
            $headers = @{"Authorization" = "Bearer $($accessToken.token)"; "Content-Type" = "application/json" };
            $uri = "$DceURI/dataCollectionRules/$DcrImmutableId/streams/Custom-$Table"+"?api-version=2021-11-01-preview";
            $uploadResponse = Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers;

            # Let's see how the response looks like
            Write-Host $uploadResponse
            Write-Host "URI: $uri"
            Write-Host "-------******---------"
        }
    } 

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
