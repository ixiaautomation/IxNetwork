################################################################################
# Version 1.0    $Revision: 1 $
# $Author: Stefan Popi $
#
#    Copyright � 1997 - 2011 by IXIA
#    All Rights Reserved.
#
#    Revision Log:
#    32-09-2011 Stefan Popi
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
###############################################################################

################################################################################
#                                                                              #
# Description:                                                                 #
#    This sample configures PCS Error Generation on a 40/100Gig port.          #
#                                                                              #
# Module:                                                                      #
#    The sample was tested on HSE 40/100GE TSP1 module                         #
#                                                                              #
################################################################################

package require Ixia

set chassis_ip              localhost
set port_list               [list 87/1 89/1]
set port_count              [llength $port_list]
set ixnetwork_tcl_server    localhost

set test_name                                   [info script]

set connect_status [::ixia::connect                                        \
        -reset                                                             \
        -device               $chassis_ip                                  \
        -port_list            $port_list                                   \
        -break_locks          1                                            \
        -username             ixiaApiUser                                  \
        ]
if {[keylget connect_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget connect_status log]"
    return 0
}

set port_handle [list]
foreach port $port_list {
    if {![catch {keylget connect_status port_handle.$chassis_ip.$port} \
                temp_port]} {
        lappend port_handle $temp_port
    }
}

set i 0
puts "Ixia port handles are:"
foreach port $port_handle {
    set port_$i $port
    puts $port
    
    # Initialize per port variables
    set interface_handles_$port ""
    
    incr i
}


#################################################################################
## Interface configuration - L1
#################################################################################
puts "Start interface configuration L1 ..."

set speed_ ether100Gig

set interface_status [::ixia::interface_config                              \
        -mode                           config                              \
        -intf_mode                      ethernet                            \
        -speed                          $speed_                             \
        -port_handle                    $port_handle                        \
        -pcs_period                     [list 10 11]                        \
        -pcs_count                      [list 9 8]                          \
        -pcs_repeat                     [list 3 2]                          \
        -pcs_period_type                [list 0 1]                          \
        -pcs_lane                       [list 3 4]                          \
        -pcs_enabled_continuous         [list 1 0]                          \
        -pcs_sync_bits                  [list 0x02 0xaf]                    \
        -pcs_marker_fields              00.00.00.19.DE.AD.BE.AD             \
        ]
if {[keylget interface_status status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget interface_status log]"
    return 0
}

puts "End interface configuration L1 ..."

# start the error generation process
set intf_status [::ixia::interface_control      \
    -port_handle           $port_handle         \
    -action                start_pcs_lane_error \
        ]
if {[keylget intf_status status] != $::SUCCESS} {
    puts "FAILURE - interface_control  -  [keylget intf_status log]"
    return 0
}

after 5000

# port statistics
set interface_stats [::ixia::interface_stats    \
        -port_handle    $port_handle            \
        ]
if {[keylget interface_stats status] != $::SUCCESS} {
    puts "FAIL - $test_name - [keylget interface_stats log]"
    return 0
}


# stop the error generation process
set intf_status [::ixia::interface_control      \
    -port_handle           $port_handle         \
    -action                stop_pcs_lane_error  \
        ]
if {[keylget intf_status status] != $::SUCCESS} {
    puts "FAILURE - interface_control  -  [keylget intf_status log]"
    return 0
}

proc show_stats var {
    set level [expr [info level] - 1]
    foreach key [keylkeys var] {
            if {$key == "status"} {continue}
            set indent [string repeat "    " $level] 
            puts -nonewline $indent 
            if {[catch {keylkeys var $key}]} {
                puts "$key: [keylget var $key]"
                continue
            } else {
                puts $key
                puts "$indent[string repeat "-" [string length $key]]"
            }
            show_stats [keylget var $key]
    }
}

puts "------------------PCS stats------------------"
show_stats $interface_stats 

return "SUCCESS - $test_name - [clock format [clock seconds]]"