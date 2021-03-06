################################################################################
# Version 1.0    $Revision: 1 $
#
#    Copyright � 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    04-8-2005  T.Kong - comply with HLTAPI V4.0 spec
#
# Description:
#
################################################################################

################################################################################
#                                                                              #
#                                LEGAL  NOTICE:                                #
#                                ==============                                #
# The following code and documentation (hereinafter "the script") is an        #
# example script for demonstration purposes only.                              #
# The script is not a standard commercial product offered by Ixia and have     #
# been developed and is being provided for use only as indicated herein. The   #
# script [and all modifications, enhancements and updates thereto (whether     #
# made by Ixia and/or by the user and/or by a third party)] shall at all times #
# remain the property of Ixia.                                                 #
#                                                                              #
# Ixia does not warrant (i) that the functions contained in the script will    #
# meet the user's requirements or (ii) that the script will be without         #
# omissions or error-free.                                                     #
# THE SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, AND IXIA        #
# DISCLAIMS ALL WARRANTIES, EXPRESS, IMPLIED, STATUTORY OR OTHERWISE,          #
# INCLUDING BUT NOT LIMITED TO ANY WARRANTY OF MERCHANTABILITY AND FITNESS FOR #
# A PARTICULAR PURPOSE OR OF NON-INFRINGEMENT.                                 #
# THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SCRIPT  IS WITH THE #
# USER.                                                                        #
# IN NO EVENT SHALL IXIA BE LIABLE FOR ANY DAMAGES RESULTING FROM OR ARISING   #
# OUT OF THE USE OF, OR THE INABILITY TO USE THE SCRIPT OR ANY PART THEREOF,   #
# INCLUDING BUT NOT LIMITED TO ANY LOST PROFITS, LOST BUSINESS, LOST OR        #
# DAMAGED DATA OR SOFTWARE OR ANY INDIRECT, INCIDENTAL, PUNITIVE OR            #
# CONSEQUENTIAL DAMAGES, EVEN IF IXIA HAS BEEN ADVISED OF THE POSSIBILITY OF   #
# SUCH DAMAGES IN ADVANCE.                                                     #
# Ixia will not be required to provide any software maintenance or support     #
# services of any kind (e.g., any error corrections) in connection with the    #
# script or any part thereof. The user acknowledges that although Ixia may     #
# from time to time and in its sole discretion provide maintenance or support  #
# services for the script, any such services are subject to the warranty and   #
# damages limitations set forth herein and will not obligate Ixia to provide   #
# any additional maintenance or support services.                              #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
# Description:                                                                 #
#    This sample creates four PIM routers on two different ports.              #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM100TXS8 module.                              #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP 127.0.0.1
set port_list [list 10/1 10/2]

# Connect to the chassis, reset to factory defaults and take ownership
# When using P2NO HLTSET, for loading the IxTclNetwork package please 
# provide �ixnetwork_tcl_server parameter to ::ixia::connect
set connect_status [::ixia::connect \
        -reset                      \
        -device    $chassisIP       \
        -port_list $port_list       \
        -username  ixiaApiUser      ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [list]
foreach port $port_list {
    if {![catch {keylget connect_status port_handle.$chassisIP.$port} \
            temp_port]} {
        lappend port_handle $temp_port
    }
}

##############################################################################
# Configure interface in the test      
# IPv6                                 
##############################################################################
set interface_status [::ixia::interface_config \
        -port_handle     $port_handle          \
        -autonegotiation 1                     \
        -duplex          full                  \
        -speed           ether100              ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

set port1_handle [lindex $port_handle 0]
set port2_handle [lindex $port_handle 1]


##############################################################################
#  Configure a PIM neighbor 
##############################################################################
set pim_config_status [::ixia::emulation_pim_config    \
        -mode                   create                  \
        -reset                                          \
        -port_handle            $port1_handle           \
        -count                  2                       \
        -ip_version             6                       \
        -intf_ip_addr           3000::1                 \
        -intf_ip_addr_step      0:0:0:1::0              \
        -intf_ip_prefix_length  64                      \
        -router_id              11.0.0.1                \
        -router_id_step         0.0.0.1                 \
        -neighbor_intf_ip_addr  4000::1                 \
        -dr_priority            10                      \
        -bidir_capable          0                       \
        -hello_interval         30                      \
        -hello_holdtime         40                      \
        -join_prune_interval    50                      \
        -join_prune_holdtime    60                      \
        -prune_delay_enable     1                       \
        -prune_delay            600                     \
        -override_interval      700                     \
        -vlan                   1                       \
        -vlan_id                300                     \
        -vlan_id_mode           increment               \
        -vlan_id_step           2                       \
        -vlan_user_priority     7                       \
        -mac_address_init       0000.0000.0001          \
        -prune_delay_tbit       1                       \
        -send_generation_id     1                       \
        -generation_id_mode     random                  \
        -writeFlag            nowrite                   ]
if {[keylget pim_config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pim_config_status log]"
}

set port1_session_handle [lindex [keylget pim_config_status handle] 0]

set pim_config_status [::ixia::emulation_pim_config     \
        -mode                   create                  \
        -reset                                          \
        -port_handle            $port2_handle           \
        -pim_mode               sm                      \
        -type                   remote_rp               \
        -count                  2                       \
        -ip_version             6                       \
        -intf_ip_addr           3000::2                 \
        -intf_ip_addr_step      0:0:0:1::0              \
        -intf_ip_prefix_length  64                      \
        -router_id              12.0.0.1                \
        -router_id_step         0.0.0.1                 \
        -neighbor_intf_ip_addr  4000::1                 \
        -dr_priority            10                      \
        -bidir_capable          0                       \
        -hello_interval         30                      \
        -hello_holdtime         40                      \
        -join_prune_interval    50                      \
        -join_prune_holdtime    60                      \
        -prune_delay_enable     1                       \
        -prune_delay            600                     \
        -override_interval      700                     \
        -vlan                   1                       \
        -vlan_id                300                     \
        -vlan_id_mode           increment               \
        -vlan_id_step           2                       \
        -vlan_user_priority     7                       \
        -mac_address_init       0000.0000.0003          \
        -prune_delay_tbit       1                       \
        -send_generation_id     1                       \
        -generation_id_mode     random                  \
        -writeFlag            nowrite                   ]
if {[keylget pim_config_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget pim_config_status log]"
}

set port2_session_handle [lindex [keylget pim_config_status handle] 0]


return "SUCCESS - $test_name - [clock format [clock seconds]]"
