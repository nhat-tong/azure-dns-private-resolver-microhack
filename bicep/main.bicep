
targetScope = 'subscription'

var vOnPremiseLocation = 'northeurope'
var vAzureLocation = 'westeurope'

resource resOnPremiseRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'onpremise02-rg'
  location: vOnPremiseLocation
  tags: {
    environment: 'onprem'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

resource resAzureHubRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'hub02-rg'
  location: vAzureLocation
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

resource resAzureSpokeRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'spoke02-rg'
  location: vAzureLocation
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

module moduleOnPremiseNetwork 'network/onprem.bicep' = {
  name: 'mod-onprem-deployment'
  scope: resOnPremiseRG
  params: {
    pRGLocation: resOnPremiseRG.location
  }
}

module moduleHubNetwork 'network/hub.bicep' = {
  name: 'mod-hub-deployment'
  scope: resAzureHubRG
  params: {
    pRGLocation: resAzureHubRG.location
  }
}

module moduleSpokeNetwork 'network/spoke.bicep' = {
  name: 'mod-spoke-deployment'
  scope: resAzureSpokeRG
  params: {
    pRGLocation: resAzureSpokeRG.location
  }
}

module moduleOnPremLng 'network/lngw-onprem.bicep' = {
  name: 'mod-onprem-lngw-deployment'
  scope: resOnPremiseRG
  params: {
    pRGLocation: resOnPremiseRG.location
  }
}

module moduleHubLng 'network/lngw-hub.bicep' = {
  name: 'mod-hub-lngw-deployment'
  scope: resAzureHubRG
  params: {
    pRGLocation: resAzureHubRG.location
  }
}

module moduleHubPrivateDnsResolver 'private-dns-resolver/dns-private-resolver-hub.bicep' = {
  scope: resAzureHubRG
  name: 'mod-hub-privatednsresolver-deployment'
  params: {
    pRGLocation: resAzureHubRG.location
  }
}

module moduleOnPremPrivateDnsResolver 'private-dns-resolver/dns-private-resolver-onpremise.bicep' = {
  scope: resOnPremiseRG
  name: 'mod-onprem-privatednsresolver-deployment'
  params: {
    pRGLocation: resAzureSpokeRG.location
  }
}

output outOnPremiseRGId string = resOnPremiseRG.id
output outAzureHubRGId string = resAzureHubRG.id
output outAzureSpokeRGId string = resAzureSpokeRG.id
