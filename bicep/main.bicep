
targetScope = 'subscription'

var vOnPremiseLocation = 'westcentralus'
var vAzureLocation = 'eastus2'

resource resOnPremiseRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'onpremise-rg'
  location: vOnPremiseLocation
  tags: {
    environment: 'onprem'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

resource resAzureHubRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'hub-rg'
  location: vAzureLocation
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

resource resAzureSpokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'spoke01-rg'
  location: vAzureLocation
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

module moduleOnPremiseNetwork 'onprem.bicep' = {
  name: 'mod-onprem-deployment'
  scope: resOnPremiseRG
  params: {
    pRGLocation: resOnPremiseRG.location
  }
}

module moduleHubNetwork 'hub.bicep' = {
  name: 'mod-hub-deployment'
  scope: resAzureHubRG
  params: {
    pRGLocation: resAzureHubRG.location
  }
}

module moduleSpokeNetwork 'spoke.bicep' = {
  name: 'mod-spoke-deployment'
  scope: resAzureSpokeRG
  params: {
    pRGLocation: resAzureSpokeRG.location
  }
}

module moduleOnPremLng 'lngw-onprem.bicep' = {
  name: 'mod-onprem-lngw-deployment'
  scope: resOnPremiseRG
  params: {
    pHubVpnGwPip: moduleHubNetwork.outputs.outHubVpnGwPip
    pHubAddressSpace: moduleHubNetwork.outputs.outHubVnetAddressSpace
    pRGLocation: resOnPremiseRG.location
  }
}

module moduleHubLng 'lngw-hub.bicep' = {
  name: 'mod-hub-lngw-deployment'
  scope: resAzureHubRG
  params: {
    pOnPremVpnGwPip: moduleOnPremiseNetwork.outputs.outOnPremiseVpnGwPip
    pOnPremAddressSpace: moduleOnPremiseNetwork.outputs.outOnPremiseVnetAddressSpace
    pRGLocation: resAzureHubRG.location
  }
}

output outOnPremiseRGId string = resOnPremiseRG.id
output outAzureHubRGId string = resAzureHubRG.id
output outAzureSpokeRGId string = resAzureSpokeRG.id
