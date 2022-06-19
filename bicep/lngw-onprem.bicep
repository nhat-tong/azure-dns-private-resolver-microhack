targetScope = 'resourceGroup'

param pRGLocation string = resourceGroup().location
param pHubVpnGwPip string
param pHubAddressSpace string

resource resOnPremiseLngw 'Microsoft.Network/localNetworkGateways@2021-08-01' = {
  name: 'onpremise-lngw'
  location: pRGLocation
  properties: {
    gatewayIpAddress: pHubVpnGwPip
    localNetworkAddressSpace: {
      addressPrefixes: [
        pHubAddressSpace
      ]
    }
  }
}

resource resOnPremiseGw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' existing = {
  name: 'onpremise-vpngw'
}

resource resOnPrem2HubConnection 'Microsoft.Network/connections@2021-08-01' = {
  name: 'onpremise-to-hub-connection'
  location: pRGLocation
  properties: {
    connectionType: 'IPsec'
    sharedKey: 'thqnhat'
    enableBgp: true
    virtualNetworkGateway1: {
      id: resOnPremiseGw.id
    }
    localNetworkGateway2: {
      id: resOnPremiseLngw.id
    }
  }
}
