targetScope = 'resourceGroup'

param pRGLocation string = resourceGroup().location

resource resOnPremVpnPIP 'Microsoft.Network/publicIPAddresses@2021-08-01' existing = {
  name: 'onpremise-vpngw-ip'
  scope: resourceGroup('onpremise02-rg')
}

resource resOnPremiseVpnGw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' existing = {
  name: 'onpremise-vpngw'
  scope: resourceGroup('onpremise02-rg')
}

resource resHubLngw 'Microsoft.Network/localNetworkGateways@2021-08-01' = {
  name: 'hub-lngw'
  location: pRGLocation
  properties: {
    gatewayIpAddress: resOnPremVpnPIP.properties['ipAddress']
    bgpSettings: {
      asn: resOnPremiseVpnGw.properties['bgpSettings'].asn
      bgpPeeringAddress: resOnPremiseVpnGw.properties['bgpSettings'].bgpPeeringAddress
    }
    localNetworkAddressSpace: {
      addressPrefixes: [
        '${resOnPremiseVpnGw.properties['bgpSettings'].bgpPeeringAddress}/32'
      ]
    }
  }
}

resource resHubVnetGw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' existing = {
  name: 'hub-vpngw2'
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
