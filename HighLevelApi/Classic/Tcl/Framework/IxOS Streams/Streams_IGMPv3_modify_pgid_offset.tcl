################################################################################
# Version 1.0    $Revision: 1 $
# $Author: Matei Vasile $
#
#    Copyright � 1997 - 2006 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    12-22-2006 Matei Vasile
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
#    This sample creates two IPv4 streams on a port.                           #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on a LM1000STXS4 module.                            #
#    The sample was tested with HLTSET26.                                      #
#                                                                              #
################################################################################

package require Ixia

set test_name [info script]

set chassisIP sylveser
set port_list [list 3/1]

# Connect to the chassis, reset to factory defaults and take ownership
set connect_status [::ixia::connect \
        -reset                      \
        -device    $chassisIP       \
        -port_list $port_list       \
        -username  ixiaApiUser      ]
if {[keylget connect_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget connect_status log]"
}

set port_handle [keylget connect_status port_handle.$chassisIP.$port_list]

########################################
# Configure interface in the test      #
# IPv4                                 #
########################################
set interface_status [::ixia::interface_config  \
        -port_handle     $port_handle           \
        -intf_ip_addr    12.1.3.2               \
        -gateway         12.1.3.1               \
        -netmask         255.255.255.0          \
        -autonegotiation 1                      \
        -src_mac_addr    0000.0005.0001         ]
if {[keylget interface_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget interface_status log]"
}

# Delete all the streams first
set traffic_status [::ixia::traffic_config \
        -mode        reset                 \
        -port_handle $port_handle          ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

set traffic_status [::ixia::traffic_config      \
        -mode               create              \
        -port_handle        $port_handle        \
        -l3_protocol        ipv4                \
        -ip_src_addr        12.1.1.1            \
        -ip_dst_addr        12.1.1.2            \
        -length_mode        fixed               \
        -frame_size         512                 \
        -enable_time_stamp  0                   \
        -enable_pgid        1                   \
        -frame_sequencing   enable              \
        -enable_data_integrity   1              \
        -integrity_signature     "FF FF FF FF"  \
        -l4_protocol  igmp                      \
        -igmp_group_addr {                      \
            224.0.1.21                          \
            224.0.1.22                          \
            224.0.1.23                          \
            224.0.1.24                          \
            224.0.1.25                          \
            224.0.1.26                          \
        }                                       \
        -igmp_record_type {                     \
            mode_is_include                     \
            mode_is_exclude                     \
            change_to_include_mode              \
            change_to_exclude_mode              \
            allow_new_sources                   \
            block_old_sources                   \
        }                                       \
        -igmp_multicast_src {                   \
            {                                   \
                21.0.0.1                        \
                21.0.0.2                        \
                21.0.0.11                       \
                21.0.0.14                       \
            }                                   \
            {                                   \
                22.0.0.71                       \
                22.0.0.32                       \
                22.0.0.13                       \
                22.0.0.54                       \
                22.0.0.5                        \
            }                                   \
            {                                   \
                23.0.0.11                       \
            }                                   \
            {                                   \
                24.0.0.1                        \
                24.0.0.12                       \
                24.0.0.3                        \
            }                                   \
            {                                   \
                25.0.0.1                        \
                25.0.0.51                       \
            }                                   \
            {                                   \
                26.0.0.62                       \
                26.0.0.63                       \
            }                                   \
        }                                       \
        -igmp_type              membership_report \
        -igmp_version           3               \
        -igmp_valid_checksum    0               \
        -rate_percent           50              \
        -mac_dst_mode           discovery       \
        -mac_src                0000.0005.0001  ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

# This should be uncommented when using a valid gateway for the interface
# configured above through the interface_config call.
if {0} {
    set interface_status [::ixia::interface_config  \
            -port_handle     $port_handle           \
            -arp_send_req    1                      ]
    if {[keylget interface_status status] != $::SUCCESS} {
        return "FAIL - $test_name - [keylget interface_status log]"
    }
    if {[catch {set failed_arp [keylget interface_status \
            $port_handle.arp_request_success]}] || $failed_arp == 0} {
        set returnLog "FAIL - $test_name arp send request failed. "
        if {![catch {set intf_list [keylget interface_status $port_handle.arp_ipv4_interfaces_failed]}]} {
            append returnLog "ARP failed on interfaces: $intf_list."
        }
        return $returnLog
    }
}

set traffic_status [::ixia::traffic_config      \
        -mode               modify              \
        -port_handle        $port_handle        \
        -enable_time_stamp  0                   \
        -stream_id          1                   \
        -l3_protocol        ipv4                \
        -ip_src_addr        42.1.1.1            \
        -ip_dst_addr        42.1.1.2            \
        -enable_auto_detect_instrumentation 0   \
        -l4_protocol        igmp                \
        -igmp_group_addr    224.0.1.27          \
        -igmp_multicast_src {                   \
            10.0.0.1                            \
            172.16.0.1                          \
            192.168.0.1                         \
        }                                       \
        -enable_pgid        1                   \
        -pgid_value         1234                \
        -pgid_offset        180                 \
        -igmp_group_mode    fixed               \
        -igmp_type          membership_query    \
        -igmp_version       3                   \
        -igmp_qqic          10                  \
        -igmp_qrv           5                   \
        -igmp_s_flag        1                   \
        -rate_percent       3                   ]
if {[keylget traffic_status status] != $::SUCCESS} {
    return "FAIL - $test_name - [keylget traffic_status log]"
}

return "SUCCESS - $test_name - [clock format [clock seconds]]"
