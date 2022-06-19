targetScope = 'resourceGroup'

param localVnetName string
param vnetPeeringName string
param remoteVnetName string
param vnetResourceGroupName string

param allowVirtualNetworkAccess bool
param allowForwardedTraffic bool
param allowGatewayTransit bool
param useRemoteGateways bool

/* VNET PEERING */
resource resVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: '${localVnetName}/${vnetPeeringName}'
  properties: {
    remoteVirtualNetwork: {
      id: resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks', remoteVnetName)
    }
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}
