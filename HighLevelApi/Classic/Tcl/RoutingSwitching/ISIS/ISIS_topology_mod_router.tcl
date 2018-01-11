################################################################################
# Version 1.0    $Revision: 1 $
# $Author: T. Kong $
#
# $Workfile: ISIS_topology_mod_router.tcl $
#
#    Copyright � 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    2-17-2005 create.
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
#    This sample creates an ISIS router and configures a route range for it.   #
#    Then modifies the route range.                                            #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM100TXS8 module.                              #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP 127.0.0.1
set port_list [list 10/1]

################################################################################
#                             START TEST                                       #
################################################################################

# Connect to the chassis, reset to factory defaults and take ownership
# When using P2NO HLTSET, for loading the IxTclNetwork package please 
# provide �ixnetwork_tcl_server parameter to ::ixia::connect
set connect_status [ ixia::connect \
        -reset                     \
        -device    $chassisIP      \
        -port_list $port_list      \
        -username  ixiaApiUser     ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [keylget connect_status port_handle.$chassisIP.$port_list]

#####################################################
#  Configure 10 ISIS L1L2 neighbors interface       #
#####################################################
set isis_router_status [::ixia::emulation_isis_config    \
        -mode                           create         \
        -reset                                            \
        -port_handle                    $port_handle   \
        -intf_ip_addr                   22.1.1.1       \
        -gateway_ip_addr                22.1.1.2       \
        -intf_ip_prefix_length          24             \
        -mac_address_init               0000.0000.0001 \
        -count                          1              \
        -wide_metrics                   0              \
        -discard_lsp                    1              \
        -attach_bit                     0              \
        -partition_repair               1              \
        -overloaded                     0              \
        -lsp_refresh_interval             10             \
        -lsp_life_time                     777            \
        -max_packet_size                1492           \
        -intf_metric                    0              \
        -routing_level                     L1L2           \
        -te_enable                      0              \
        -te_router_id                   198.0.0.1      \
        -te_max_bw                         10             \
        -te_max_resv_bw                 20             \
        -te_unresv_bw_priority0          0             \
        -te_unresv_bw_priority1         10             \
        -te_unresv_bw_priority2         20             \
        -te_unresv_bw_priority3         30             \
        -te_unresv_bw_priority4         40             \
        -te_unresv_bw_priority5         50             \
        -te_unresv_bw_priority6         60             \
        -te_unresv_bw_priority7         70             \
        -te_metric                      10]
if {[keylget isis_router_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget isis_router_status log]"
}

#Get the list of ISIS router handle form the keye list returned
set isis_router_handle_list [keylget isis_router_status handle]

##############################################################
#  For each ISIS router configure 2 IPv4 route range on each #
##############################################################

set isis_router_handle [lindex $isis_router_handle_list 0]
puts "isis_router_handle = $isis_router_handle"

#foreach isis_router_handle [lindex $isis_router_handle_list 0] /{

    set route_config_status [::ixia::emulation_isis_topology_route_config \
            -mode                   create                  \
            -handle                 $isis_router_handle     \
            -type                   router                  \
            -ip_version             4_6                     \
            -router_system_id       112233445566            \
            -router_id              44.0.0.1                \
            -router_area_id         000001 000002 112233    \
            -link_ip_addr           198.0.0.1               \
            -link_ip_prefix_length  24                      \
            -link_enable            1                       \
            -link_ipv6_addr         4000::1                 \
            -link_ipv6_prefix_length 64                     \
            -link_narrow_metric      10                     \
            -link_wide_metric        999                    \
            -link_te                 1                      \
            -link_te_metric          77                     \
            -link_te_max_bw          1000                   \
            -link_te_max_resv_bw     9999                   \
            -link_te_unresv_bw_priority0    0               \
            -link_te_unresv_bw_priority1    1               \
            -link_te_unresv_bw_priority2    2               \
            -link_te_unresv_bw_priority3    3               \
            -link_te_unresv_bw_priority4    4               \
            -link_te_unresv_bw_priority5    5               \
            -link_te_unresv_bw_priority6    6               \
            -link_te_unresv_bw_priority7    7               \
            -link_te_admin_group    100                     \
            ]

    if {[keylget route_config_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget route_config_status log]"
    }

    set elem_handle [keylget route_config_status elem_handle]
    puts "elem_handle = $elem_handle"


################################
#  Modify the topology element #
################################
    set route_config_status [::ixia::emulation_isis_topology_route_config \
            -mode                   modify                  \
            -handle                 $isis_router_handle     \
            -elem_handle            $elem_handle            \
            -ip_version             4_6                     \
            -router_system_id       010203040506            \
            -router_id              44.0.0.9                \
            -router_area_id         000001 000002 999999    \
            -link_ip_addr           198.0.0.9               \
            -link_ip_prefix_length  24                      \
            -link_enable            1                       \
            -link_ipv6_addr         4000::9                 \
            -link_ipv6_prefix_length 64                     \
            -link_narrow_metric      10                     \
            -link_wide_metric        999                    \
            -link_te                 1                      \
            -link_te_metric          77                     \
            -link_te_max_bw          1000                   \
            -link_te_max_resv_bw     9999                   \
            -link_te_unresv_bw_priority0    09              \
            -link_te_unresv_bw_priority1    19              \
            -link_te_unresv_bw_priority2    29              \
            -link_te_unresv_bw_priority3    39              \
            -link_te_unresv_bw_priority4    49              \
            -link_te_unresv_bw_priority5    59              \
            -link_te_unresv_bw_priority6    69              \
            -link_te_unresv_bw_priority7    79              \
            -link_te_admin_group    999                     \
            ]

    if {[keylget route_config_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget route_config_status log]"
    }

    set elem_handle [keylget route_config_status elem_handle]




######################
# START ISIS         #
######################
set isis_emulation_status [::ixia::emulation_isis_control \
        -handle      $isis_router_handle                \
        -mode        start                              ]
if {[keylget isis_emulation_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget isis_emulation_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
