targetScope = 'resourceGroup'

param pRGLocation string = resourceGroup().location

resource resAzureVpnPIP 'Microsoft.Network/publicIPAddresses@2021-08-01' existing = {
  name: 'hub-vpngw-ip'
  scope: resourceGroup('hub02-rg')
}

resource resAzureVpnGw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' existing = {
  name: 'hub-vpngw2'
  scope: resourceGroup('hub02-rg')
}

resource resOnPremiseLngw 'Microsoft.Network/localNetworkGateways@2021-08-01' = {
  name: 'onpremise-lngw'
  location: pRGLocation
  properties: {
    gatewayIpAddress: resAzureVpnPIP.properties['ipAddress']
    bgpSettings: {
      asn: resAzureVpnGw.properties['bgpSettings'].asn
      bgpPeeringAddress: resAzureVpnGw.properties['bgpSettings'].bgpPeeringAddress
    }
    localNetworkAddressSpace: {
      addressPrefixes: [
        '${resAzureVpnGw.properties['bgpSettings'].bgpPeeringAddress}/32'
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
