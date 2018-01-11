################################################################################
# Version 1.0    $Revision: 1 $
# $Author: Karim $
#
#    Copyright � 1997 - 2005 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    4-25-2003 Karim
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
#    This sample configures two internal BGP neighbors and on each neighbor it #
#    adds two VRFs.                                                            #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM100TXS8 module.                              #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP 127.0.0.1
set port_list [list 10/1]

# Connect to the chassis, reset to factory defaults and take ownership
# When using P2NO HLTSET, for loading the IxTclNetwork package please 
# provide �ixnetwork_tcl_server parameter to ::ixia::connect
set connect_status [::ixia::connect \
        -reset                \
        -device    $chassisIP \
        -port_list $port_list \
        -username  ixiaApiUser]

if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [::ixia::get_port_list_from_connect $connect_status $chassisIP \
        $port_list]

########################################
# Configure interface in the test      #
#                                      #
# IPv4                                 #
########################################
set interface_status [::ixia::interface_config \
        -port_handle     $port_handle \
        -autonegotiation 1            \
        -duplex          auto         \
        -speed           auto         ]

if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

#################################################
#                                               #
#  Configure 1 BGP neighbors on interface 1/10/1 #
#  1) Neighbor #1 - internal                    #
#################################################
set bgp_routers_status [::ixia::emulation_bgp_config    \
        -mode                            reset          \
        -port_handle                     $port_handle   \
        -local_ip_addr                   10.1.1.1       \
        -remote_ip_addr                  10.1.1.2       \
        -local_addr_step                 0.1.0.0        \
        -remote_addr_step                0.1.0.0        \
        -local_loopback_ip_addr          6.6.6.6        \
        -remote_loopback_ip_addr         5.5.5.5        \
        -local_loopback_ip_addr_step     0.1.0.0        \
        -remote_loopback_ip_addr_step    0.1.0.0        \
        -count                           2              \
        -mac_address_start               0000.0000.0001 \
        -local_router_id                 10.1.1.1       \
        -neighbor_type                   internal       \
        -ip_version                      4              \
        -next_hop_enable                                \
        -next_hop_ip                     10.10.160.1    \
        -local_as                        111            \
        -local_as_mode                   fixed          \
        -tcp_window_size                 6666           \
        -updates_per_iteration           5              \
        -retries                         11             \
        -retry_time                      22             \
        -active_connect_enable                          \
        -staggered_start_enable                         \
        -ipv4_mpls_vpn_nlri                             \
        -staggered_start_time            77             ]

if {[keylget bgp_routers_status status] != $::SUCCESS} {
    return "FAIL - $test_name -\
            [keylget bgp_routers_status log]"
}

#############################################
# Configure L3 VPN Site on the BGP Neighbor #
#############################################
# Extract the BGP neighbor handle from status
set bgp_neighbor_handle_list [keylget bgp_routers_status handles]
set bgp_neighbor1 [lindex $bgp_neighbor_handle_list 0]
set bgp_neighbor2 [lindex $bgp_neighbor_handle_list 1]

set bgp_route_range_status [::ixia::emulation_bgp_route_config \
        -mode                 add                       \
        -handle               $bgp_neighbor1            \
        -ip_version           4                         \
        -prefix               1.1.1.1                   \
        -prefix_step          1                         \
        -netmask              255.255.255.0             \
        -label_value          55                        \
        -num_sites            2                         \
        -num_routes           100                       \
        -label_step           1                         \
        -rd_type              1                         \
        -rd_admin_value       9.9.9.9                   \
        -rd_assign_value      555                       \
        -rd_admin_step        0.0.0.1                   \
        -rd_assign_step       5                         \
        -target_type          "as as as"                \
        -target               "100 150 200"             \
        -target_assign        "44 55 66"                \
        -import_target_type   "ip ip as"                \
        -import_target        "200.1.1.1 100.1.1.1 200" \
        -import_target_assign "150 77 88"               \
        -ipv4_unicast_nlri                              \
        -ipv4_multicast_nlri                            \
        -ipv4_mpls_nlri                                 \
        -ipv4_mpls_vpn_nlri                             \
        -ipv6_unicast_nlri                              \
        -ipv6_multicast_nlri                            \
        -ipv6_mpls_nlri                                 \
        -ipv6_mpls_vpn_nlri                             ]

if {[keylget bgp_route_range_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget bgp_route_range_status log]"
}

set bgp_route_range_status [::ixia::emulation_bgp_route_config \
        -mode                 add                 \
        -handle               $bgp_neighbor2      \
        -ip_version           4                   \
        -prefix               2.2.2.2             \
        -prefix_step          1                   \
        -netmask              255.255.255.0       \
        -label_value          255                 \
        -num_sites            2                   \
        -num_routes           500                 \
        -label_step           1                   \
        -rd_type              1                   \
        -rd_admin_value       10.10.10.10         \
        -rd_assign_value      777                 \
        -rd_admin_step        0.0.0.1             \
        -rd_assign_step       10                  \
        -target_type          "as ip as"          \
        -target               "100 100.1.1.1 200" \
        -target_assign        "44 55 66"          \
        -import_target_type   "as ip as"          \
        -import_target        "100 100.1.1.1 200" \
        -import_target_assign "66 77 88"          \
        -ipv4_unicast_nlri                        \
        -ipv4_multicast_nlri                      \
        -ipv4_mpls_nlri                           \
        -ipv4_mpls_vpn_nlri                       \
        -ipv6_unicast_nlri                        \
        -ipv6_multicast_nlri                      \
        -ipv6_mpls_nlri                           \
        -ipv6_mpls_vpn_nlri                       ]

if {[keylget bgp_route_range_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget bgp_route_range_status log]"
}

######################
# START BGP on       #
######################
#set bgp_emulation_status [::ixia::emulation_bgp_control \
#                            -handle $port_handle \
#                            -mode start]
#
#if {[keylget bgp_emulation_status status] != $::SUCCESS} {
#    return "FAIL - $test_name -\
#            [keylget bgp_emulation_status log]"
#}

return "SUCCESS - $test_name -\
        [clock format [clock seconds]]"
