targetScope = 'resourceGroup'

param pRGLocation string = resourceGroup().location
param pOnPremVpnGwPip string
param pOnPremAddressSpace string

resource resHubLngw 'Microsoft.Network/localNetworkGateways@2021-08-01' = {
  name: 'hub-lngw'
  location: pRGLocation
  properties: {
    gatewayIpAddress: pOnPremVpnGwPip
    localNetworkAddressSpace: {
      addressPrefixes: [
        pOnPremAddressSpace
      ]
    }
  }
}

resource resHubVnetGw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' existing = {
  name: 'hub-vpngw'
}

resource resHub2OnPremConnection 'Microsoft.Network/connections@2021-08-01' = {
  name: 'hub-to-onpremise-connection'
  location: pRGLocation
  properties: {
    connectionType: 'IPsec'
    sharedKey: 'thqnhat'
    enableBgp: true
    virtualNetworkGateway1: {
      id: resHubVnetGw.id
    }
    localNetworkGateway2: {
      id: resHubLngw.id
    }
  }
}
