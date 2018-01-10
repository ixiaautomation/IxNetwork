
# PLEASE READ DISCLAIMER
#
#    This is a sample script for demo and reference purpose only.
#    It is subject to change for content updates without warning.
#
# REQUIREMENTS
#    - Python2.7
#    - Python modules: requests
#
# DESCRIPTION
#    This sample script demonstrates:
#        - REST API configurations using two back-to-back Ixia ports.
#        - Connecting to Windows IxNetwork API server or Linux API server.
#
#        - Configure two IPv4/OSPF Topology Groups
#        - Start protocols
#        - Verify OSPF protocol sessions
#        - Create a Traffic Item
#        - Apply Traffic
#        - Start Traffic
#        - Get stats
#
# USAGE
#    python <script>.py windows
#    python <script>.py linux

import sys, traceback
from IxNetRestApi import *
from IxNetRestApiPortMgmt import PortMgmt
from IxNetRestApiTraffic import Traffic
from IxNetRestApiProtocol import Protocol
from IxNetRestApiStatistics import Statistics

# Default the API server to either windows or linux.
connectToApiServer = 'windows'

if len(sys.argv) > 1:
    if sys.argv[1] not in ['windows', 'windowsConnectionMgr', 'linux']:
        sys.exit("\nError: %s is not a known option. Choices are 'windows', 'windowsConnectionMgr or 'linux'." % sys.argv[1])
    connectToApiServer = sys.argv[1]

try:
    #---------- Preference Settings --------------

    forceTakePortOwnership = True
    releasePortsWhenDone = False
    enableDebugTracing = False
    deleteSessionAfterTest = True ;# For Windows Connection Mgr and Linux API server only

    ixChassisIp = '192.168.70.11'
    # [chassisIp, cardNumber, slotNumber]
    portList = [[ixChassisIp, '1', '1'],
               [ixChassisIp, '2', '1']]

    if connectToApiServer == 'linux':
        mainObj = Connect(apiServerIp='192.168.70.144',
                          serverIpPort='443',
                          username='admin',
                          password='admin',
                          deleteSessionAfterTest=deleteSessionAfterTest,
                          verifySslCert=False,
                          serverOs=connectToApiServer)

    if connectToApiServer in ['windows', 'windowsConnectionMgr']:
        mainObj = Connect(apiServerIp='192.168.70.127',
                          serverIpPort='11009',
                          serverOs=connectToApiServer,
                          deleteSessionAfterTest=deleteSessionAfterTest)

    #---------- Preference Settings End --------------

    portObj = PortMgmt(mainObj)
    portObj.connectIxChassis(ixChassisIp)

    if portObj.arePortsAvailable(portList, raiseException=False) != 0:
        if forceTakePortOwnership == True:
            portObj.releasePorts(portList)
        else:
            raise IxNetRestApiException('Ports are owned by another user and forceTakePortOwnership is set to False')

    mainObj.configLicenseServerDetails(['192.168.70.127'], 'subscription', 'tier3')
    mainObj.newBlankConfig()

    # Set createVports True if building config from scratch.
    portObj.assignPorts(portList, createVports=True)

    protocolObj = Protocol(mainObj, portObj)
    topologyObj1 = protocolObj.createTopologyNgpf(portList=[portList[0]], topologyName='Topo1')
    
    deviceGroupObj1 = protocolObj.createDeviceGroupNgpf(topologyObj1,
                                                        multiplier=1,
                                                        deviceGroupName='DG1')
    
    topologyObj2 = protocolObj.createTopologyNgpf(portList=[portList[1]], topologyName='Topo2')
    
    deviceGroupObj2 = protocolObj.createDeviceGroupNgpf(topologyObj2,
                                                        multiplier=1,
                                                        deviceGroupName='DG2')
    
    ethernetObj1 = protocolObj.createEthernetNgpf(deviceGroupObj1,
                                                  ethernetName='MyEth1',
                                                  macAddress={'start': '00:01:01:00:00:01',
                                                              'direction': 'increment',
                                                              'step': '00:00:00:00:00:01'},
                                                  macAddressPortStep='disabled')
    
    
    ethernetObj2 = protocolObj.createEthernetNgpf(deviceGroupObj2,
                                                  ethernetName='MyEth2',
                                                  macAddress={'start': '00:01:02:00:00:01',
                                                              'direction': 'increment',
                                                              'step': '00:00:00:00:00:01'},
                                                  macAddressPortStep='disabled')
    
    ipv4Obj1 = protocolObj.createIpv4Ngpf(ethernetObj1,
                                          ipv4Address={'start': '1.1.1.1',
                                                       'direction': 'increment',
                                                       'step': '0.0.0.1'},
                                          ipv4AddressPortStep='disabled',
                                          gateway={'start': '1.1.1.2',
                                                   'direction':'increment',
                                                   'step': '0.0.0.0'},
                                          gatewayPortStep='disabled',
                                          prefix=24,
                                          resolveGateway=True)
    
    ipv4Obj2 = protocolObj.createIpv4Ngpf(ethernetObj2,
                                          ipv4Address={'start': '1.1.1.2',
                                                       'direction': 'increment',
                                                       'step': '0.0.0.1'},
                                          ipv4AddressPortStep='disabled',
                                          gateway={'start': '1.1.1.1',
                                                   'direction': 'increment',
                                                   'step': '0.0.0.0'},
                                          gatewayPortStep='disabled',
                                          prefix=24,
                                          resolveGateway=True)
    
    ospfObj1 = protocolObj.configOspf(ipv4Obj1,
                                      name = 'ospf_1',
                                      areaId = '0',
                                      neighborIp = '1.1.1.2',
                                      helloInterval = '10',
                                      areaIdIp = '0.0.0.0',
                                      networkType = 'pointtomultipoint',
                                      deadInterval = '40')
    
    ospfObj2 = protocolObj.configOspf(ipv4Obj2,
                                      name = 'ospf_2',
                                      areaId = '0',
                                      neighborIp = '1.1.1.1',
                                      helloInterval = '10',
                                      areaIdIp = '0.0.0.0',
                                      networkType = 'pointtomultipoint',
                                      deadInterval = '40')
    
    networkGroupObj1 = protocolObj.configNetworkGroup(create=deviceGroupObj1,
                                                      name='networkGroup1',
                                                      multiplier = 100,
                                                      networkAddress = {'start': '160.1.0.0',
                                                                        'step': '0.0.0.1',
                                                                        'direction': 'increment'},
                                                      prefixLength = 24)
    
    networkGroupObj2 = protocolObj.configNetworkGroup(create=deviceGroupObj2,
                                                      name='networkGroup2',
                                                      multiplier = 100,
                                                      networkAddress = {'start': '180.1.0.0',
                                                                        'step': '0.0.0.1',
                                                                        'direction': 'increment'},
                                                      prefixLength = 24)
    
    protocolObj.startAllProtocols()
    protocolObj.verifyArp(ipType='ipv4')
    protocolObj.verifyProtocolSessionsNgpf()
    
    # For all parameter options, please go to the API configTrafficItem
    # mode = create or modify
    trafficObj = Traffic(mainObj)
    trafficStatus = trafficObj.configTrafficItem(mode='create',
                                                 trafficItem = {
                                                     'name':'Topo1 to Topo2',
                                                     'trafficType':'ipv4',
                                                     'biDirectional':True,
                                                     'srcDestMesh':'one-to-one',
                                                     'routeMesh':'oneToOne',
                                                     'allowSelfDestined':False,
                                                     'trackBy': ['flowGroup0']},
                                                 endpoints = [({'name':'Flow-Group-1',
                                                                'sources': [topologyObj1],
                                                                'destinations': [topologyObj2]},
                                                               {'highLevelStreamElements': None})
                                                          ],
                                                 configElements = [{'transmissionType': 'fixedFrameCount',
                                                                    'frameCount': 50000,
                                                                    'frameRate': 88,
                                                                    'frameRateType': 'percentLineRate',
                                                                    'frameSize': 128}])
    
    trafficItemObj   = trafficStatus[0]
    endpointObj      = trafficStatus[1][0]
    configElementObj = trafficStatus[2][0]

    trafficObj.regenerateTrafficItems()
    trafficObj.applyTraffic()
    trafficObj.startTraffic()

    # Check the traffic state to assure traffic has indeed stopped before checking for stats.
    if trafficObj.getTransmissionType(configElementObj) == "fixedFrameCount":
        trafficObj.checkTrafficState(expectedState=['stopped', 'stoppedWaitingForStats'], timeout=45)

    statObj = Statistics(mainObj)
    stats = statObj.getStats(viewName='Flow Statistics')

    print('\n{txPort:10} {txFrames:15} {rxPort:10} {rxFrames:15} {frameLoss:10}'.format(
        txPort='txPort', txFrames='txFrames', rxPort='rxPort', rxFrames='rxFrames', frameLoss='frameLoss'))
    print('-'*90)

    for flowGroup,values in stats.items():
        txPort = values['Tx Port']
        rxPort = values['Rx Port']
        txFrames = values['Tx Frames']
        rxFrames = values['Rx Frames']
        frameLoss = values['Frames Delta']

        print('{txPort:10} {txFrames:15} {rxPort:10} {rxFrames:15} {frameLoss:10} '.format(
            txPort=txPort, txFrames=txFrames, rxPort=rxPort, rxFrames=rxFrames, frameLoss=frameLoss))

    if releasePortsWhenDone == True:
        portObj.releasePorts(portList)

    if connectToApiServer == 'linux':
        mainObj.linuxServerStopAndDeleteSession()

    if connectToApiServer == 'windowsConnectionMgr':
        mainObj.deleteSession()

except (IxNetRestApiException, Exception, KeyboardInterrupt) as errMsg:
    if enableDebugTracing:
        if not bool(re.search('ConnectionError', traceback.format_exc())):
            print('\n%s' % traceback.format_exc())
    print('\nException Error! %s\n' % errMsg)
    if 'mainObj' in locals() and connectToApiServer == 'linux':
        mainObj.linuxServerStopAndDeleteSession()
    if 'mainObj' in locals() and connectToApiServer in ['windows', 'windowsConnectionMgr']:
        if releasePortsWhenDone and forceTakePortOwnership:
            portObj.releasePorts(portList)