################################################################################
# Version 1.1    $Revision: 2 $
# $Author: Karim $
#
#    Copyright � 1997 - 2007 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    4-1-2004 Karim
#    3-2-2007 updated for HLTAPI 3.00 - Matei-Eugen Vasile
#    7-11-2007 set peer_discovery to basic in order to be able to
#              add ATM ranges - Matei-Eugen Vasile
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
#    This sample creates two LDP peers on a ATM port.                          #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM622MR module.                                #
#                                                                              #
################################################################################

lappend auto_path {D:\p4\hltapi\3.00}

set env(IXIA_VERSION) HLTSET22

package require Ixia

set test_name [info script]

set chassisIP 10.205.19.151
set port_list [list 6/1]

# Connect to the chassis, reset to factory defaults and take ownership
# When using P2NO HLTSET, for loading the IxTclNetwork package please 
# provide �ixnetwork_tcl_server parameter to ::ixia::connect
set connect_status [::ixia::connect \
        -reset                    \
        -device    $chassisIP     \
        -port_list $port_list     \
        -username  ixiaApiUser    ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [keylget connect_status port_handle.$chassisIP.$port_list]

########################################
# Configure interface in the test      #
# IPv4                                 #
########################################
set interface_status [::ixia::interface_config \
        -port_handle     $port_handle        \
        -atm_enable_coset            0       \
        -atm_enable_pattern_matching 0       \
        -atm_filler_cell             idle    \
        -atm_interface_type          nni     \
        -atm_packet_decode_mode      cell    \
        -atm_reassembly_timeout      5       \
        ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

#################################################
#  Configure 2 LDP peers on interface 1/10/1    #
#################################################
set ldp_routers_status [::ixia::emulation_ldp_config \
        -mode                  create              \
        -port_handle           $port_handle        \
        -label_adv             on_demand           \
        -peer_discovery        link                \
        -count                 2                   \
        -intf_ip_addr          11.1.1.2            \
        -intf_prefix_length    24                  \
        -intf_ip_addr_step     0.0.1.0             \
        -lsr_id                10.10.10.10         \
        -label_space           60                  \
        -lsr_id_step           0.0.1.0             \
        -mac_address_init      0000.0000.0001      \
        -hello_interval        5                   \
        -hello_hold_time       10                  \
        -keepalive_interval    5                   \
        -keepalive_holdtime    10                  \
        -discard_self_adv_fecs 1                   \
        -atm_encapsulation     LLCRoutedCLIP       \
        -vpi                   50                  \
        -vpi_step              1                   \
        -vci                   1010                \
        -vci_step              20                  \
        -atm_range_max_vpi     200                 \
        -atm_range_min_vpi     1                   \
        -atm_range_max_vci     60000               \
        -atm_range_min_vci     35                  \
        -enable_l2vpn_vc_fecs  1                   \
        -enable_vc_group_matching 1                \
        -gateway_ip_addr       11.1.1.1            \
        -gateway_ip_addr_step  0.0.1.0             \
        -reset                                     \
        -targeted_hello_hold_time 22               \
        -targeted_hello_interval 10                ]

if {[keylget ldp_routers_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget ldp_routers_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
