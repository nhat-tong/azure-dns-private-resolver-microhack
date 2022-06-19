### Create all

```
az deployment sub create --location westeurope --confirm-with-what-if --template-file=./bicep/main.bicep --no-wait
```

### Deploy Azure Vnet & Azure Vpn Gateway
```
az deployment group create --confirm-with-what-if --template-file=./bicep/onprem.bicep --resource-group onpremise02-rg --no-wait

az deployment group create --confirm-with-what-if --template-file=./bicep/hub.bicep --resource-group hub02-rg --no-wait

az deployment group create --confirm-with-what-if --template-file=./bicep/spoke.bicep --resource-group spoke02-rg --no-wait
```
### Deploy Local Network Gateway
```
az deployment group create --confirm-with-what-if --template-file=./bicep/lngw-hub.bicep --resource-group hub02-rg --no-wait

az deployment group create --confirm-with-what-if --template-file=./bicep/lngw-onprem.bicep --resource-group onpremise02-rg --no-wait
```

### Deploy dns private resolver
```
az deployment group create --confirm-with-what-if --template-file=./bicep/dns-private-resolver-hub.bicep --resource-group hub02-rg --no-wait

az deployment group create --confirm-with-what-if --template-file=./bicep/dns-private-resolver-onpremise.bicep --resource-group onpremise02-rg --no-wait
```