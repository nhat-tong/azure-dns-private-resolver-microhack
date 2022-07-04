### Create all

```
az deployment sub create --location westeurope --confirm-with-what-if --template-file=./bicep/main.bicep --no-wait
```

### 1. Deploy Azure Vnet & Azure Vpn Gateway
```
az deployment group create --confirm-with-what-if --template-file=./bicep/network/onprem.bicep --resource-group onpremise02-rg --no-wait

az deployment group create --confirm-with-what-if --template-file=./bicep/network/hub.bicep --parameters @./bicep/network/hub.parameters.json -pAdminUsername [YOUR_ADMIN_USER] -pAdminPassword [YOUR_ADMIN_PASSWORD] --resource-group [HUB_RG] --no-wait

az deployment group create --confirm-with-what-if --template-file=./bicep/network/spoke.bicep --resource-group spoke02-rg --no-wait
```
### 2. Deploy Local Network Gateway
```
az deployment group create --confirm-with-what-if --template-file=./bicep/network/lngw-hub.bicep --resource-group hub02-rg --no-wait

az deployment group create --confirm-with-what-if --template-file=./bicep/network/lngw-onprem.bicep --resource-group onpremise02-rg --no-wait
```

### 3. Deploy Dns Private Resolver
```
az deployment group create --confirm-with-what-if --template-file=./bicep/private-dns-resolver/dns-private-resolver-hub.bicep --resource-group hub02-rg --no-wait

az deployment group create --confirm-with-what-if --template-file=./bicep/private-dns-resolver/dns-private-resolver-onpremise.bicep --resource-group onpremise02-rg --no-wait
```

### 4. Deploy Azure Firewall & Log Analytic Workspace

```
az deployment group create --confirm-with-what-if --template-file=./bicep/private-dns-resolver/azure-firewall.bicep --resource-group hub02-rg --no-wait
```