#!/usr/bin/env tclsh
#md5sum="61dd5375a7300ff44be486f86e04153c"
#
# * Copyright (c) 2015 by Cisco Systems, Inc.
# * All rights reserved.
#
# The above is the (embedded) md5sum of this file taken without this line, 
# can be # created this way: 
#f=poap_script.tcl; cat $f | sed '/^#md5sum/d' > $f.md5 ; sed -i "s/^#md5sum=.*/#md5sum=\"$(md5sum $f.md5 | sed 's/ .*//')\"/" $f
# This way this script's integrity can be checked in case you do not trust
# tftp's ip checksum. This integrity check is done by /isan/bin/poap.bin).
# The integrity of the files downloaded later (images, config) is checked 
# by downloading the corresponding file with the .md5 extension and is
# done by this script itself.

# **** Here are all variables that parametrize this script **** 
# *************************************************************

#REPLACE image versions or directly modify the image src below
set n3k_image_version    "7.3.0.D1.1"
set n5k_image_version    "7.3.0.D1.1"
set n6k_image_version    "7.3.0.D1.1"
set n7k_image_version    "7.3.0.D1.1"
set m9250_image_version    "7.3.0.DY.1"
set m9148s_image_version    "7.3.0.DY.1"
set m9300_image_version    "7.3.0.DY.1"
set m9500_image_version    "7.3.0.DY.1"
set m9700_image_version    "7.3.0.DY.1"



# REPLACE below system/kickstart image source to the images you want POAP to download
set n3k_system_image_src    [format "n3000-uk9.%s.bin" $n3k_image_version] 
set n3k_kickstart_image_src [format "n3000-uk9-kickstart.%s.bin" $n3k_image_version] 
set n5k_system_image_src    [format "n5000-uk9.%s.bin" $n5k_image_version] 
set n5k_kickstart_image_src [format "n5000-uk9-kickstart.%s.bin" $n5k_image_version] 
set n7k_system_image_src    [format "n7000-s1-dk9.%s.bin" $n7k_image_version] 
set n7k_kickstart_image_src [format "n7000-s1-kickstart.%s.bin" $n7k_image_version] 
set n6k_system_image_src    [format "n6000-uk9.%s.bin" $n6k_image_version] 
set n6k_kickstart_image_src [format "n6000-uk9-kickstart.%s.bin" $n6k_image_version] 
set titanium_system_image_src    "titanium-54.s"
set titanium_kickstart_image_src "titanium-54.k"
set m9250_kickstart_image_src [format "m9250-s5ek9-kickstart-mz.%s.bin" $m9250_image_version]
set m9250_system_image_src [format "m9250-s5ek9-mz.%s.bin" $m9250_image_version]
set m9148s_kickstart_image_src [format "m9100-s5ek9-kickstart-mz.%s.bin" $m9148s_image_version]
set m9148s_system_image_src [format "m9100-s5ek9-mz.%s.bin" $m9148s_image_version]
set m9300_kickstart_image_src [format "m9300-s1ek9-kickstart-mz.%s.bin" $m9300_image_version]
set m9300_system_image_src [format "m9300-s1ek9-mz.%s.bin" $m9300_image_version]
set m9500_kickstart_image_src [format "m9500-sf2ek9-kickstart-mz.%s.bin" $m9500_image_version]
set m9500_system_image_src [format "m9500-sf2ek9-mz.%s.bin" $m9500_image_version]
set m9700_system_image_src [format "m9700-sf3ek9-mz.%s.bin" $m9700_image_version]
set m9700_kickstart_image_src [format "m9700-sf3ek9-kickstart-mz.%s.bin" $m9700_image_version]

# REPLACE below line with the dir info on TFTP server 
set image_dir_src       "/vinci-tftpboot/"
set config_path         "/vinci-tftpboot/hybrid/"

# REPLACE below line with config filename
set config_file_src     "poap.cfg"

# Destination file names the below files will be stored as on the device
set image_dir_dst       "bootflash:poap"
set system_image_dst    "bootflash:system.img" 
set kickstart_image_dst "bootflash:kickstart.img"
set config_db_file_dst  "bootflash:poap_database_dst.cfg" 
set config_file_dst     "bootflash:poap_dst.cfg" 
set config_file_dst_tmp  "bootflash:poap_dst1.cfg" 

# Destination file name for those lines in config which need reboot 
# example: system vlan or interface breakout or hardware profile tcam
set config_file_dst_first   "bootflash:poap_1.cfg"

# Desination file name for those lines in config which does not match above criterea.
set config_file_dst_second "bootflash:poap_2.cfg"

# indicates whether first config file is empty or not
set emptyFirstFile 1

# indicates whether the files have been copied or not
set FoundTemplate 0
set config_copied 0
set system_image_copied 0
set kickstart_image_copied 0
set template_config_copied 0
set database_copied 0

# indicates whether the final config generated is available or not
set generatedConfig 0

# extension of file containing md5sum of the one without ext.
set md5sum_ext_src      "md5" 
# there is no md5sum_ext_dst because one the target it is a temp file
# Required space on /bootflash (for config and kick/system images)
set required_space 250000 

# Protocol to use to download images/config
# Supported protocols are scp/sftp/ftp/tftp
set protocol "scp" 

# Host name and user credentials
# REPLACE below 3 lines with your TFTP server info
set username "root"
set password "cisco123"
set hostname "90.90.90.166" 

# Timeout info (from biggest to smallest image, should be f(image-size, protocol))
set system_timeout    2100 
set kickstart_timeout 900  
set config_timeout    120 
set md5sum_timeout    120  

# POAP can use 6 modes to obtain the config file.
# - 'static' - filename is static
# - 'serial_number' - switch serial number is part of the filename
#    if serial-number is abc, then filename is conf_abc.cfg
# - 'location' - CDP neighbor of interface on which DHCPDISCOVER arrived
#                is part of filename
#    if cdp neighbor's device_id=abc and port_id=111,
#    then filename is conf_abc_111.cfg
# - 'mac' - use the interface (mgmt 0 interface / Single MAC address for all the
#        front-panel interface) MAC address to derive the configuration filename
#        (Example: for MAC Address 00:11:22:AA:BB:CC" the default configuration
#        file looked for would be conf_001122AABBCC.cfg
# - 'hostname' - Use the hostname from the DHCP OFFER to derive the configuration
#       file name (Example: conf_N5K-Switch-1.cfg for hostname 'N5K-Switch-1'
# - 'database' - config file is obtained from a database
# Note: the next line can be overwritten by command-line arg processing later
set config_file_type "serial_number"

# parameters passed through environment:
set pid ""
if { [info exists env(POAP_PID)] && ![string equal $env(POAP_PID) ""] } {
    set pid $env(POAP_PID)
}
set serial_number ""
if { [info exists env(POAP_SERIAL)] && ![string equal $env(POAP_SERIAL) ""] } {
    set serial_number $env(POAP_SERIAL)
}
set cdp_interface ""
if { [info exists env(POAP_INTF)] && ![string equal $env(POAP_INTF) ""] } { 
    set cdp_interface $env(POAP_INTF)
}

# vrf info
set vrf "management"
if { [info exists env(POAP_VRF)] && ![string equal $env(POAP_VRF) ""] } {
    set vrf $env(POAP_VRF)
}

# POAP phase info (USB or DHCP)
set poap_phase ""
if { [info exists env(POAP_PHASE)] && ![string equal $env(POAP_PHASE) ""] } {
    set poap_phase $env(POAP_PHASE)
}

# will append date/timespace into the name later
set log_filename "/bootflash/poap.log"
set now ""

# **** end of parameters **** 

# *************************************************************
# ***** argv parsing and online help (for test through cli) ******
# ****************************************************************

# poap.bin passes args (serial-number/cdp-interface) through env var
# for no seeminly good reason: we allow to overwrite those by passing
# argv, this is usufull when testing the script from vsh (even simple
# script have many cases to test, going through a reboto takes too long)

# Command Line version of cdp-interface
set cl_cdp_interface ""  
# can overwrite the corresp. env var
set cl_serial_number ""  

proc parse_args {argv_list {help ""} } {
    global cl_cdp_interface cl_serial_number
    foreach { a b } $argv_list {
        if {[string compare -length [string length $a] $a "cdp-interface"] == 0} {
           catch {
                set cl_cdp_interface $b
            } error
            if {$error != ""} {
                if { $help !="" } {
                    set cl_cdp_interface -1
                }
            }
            if {[string length $a]!=[string length "cdp-interface"] && $help!=""} {
                set cl_cdp_interface ""
            }
            continue
        }
        if {[string compare -length [string length $a] $a "serial-number"] == 0} {
            catch {
                set cl_serial_number $b
            } error
            if {$error!=""} {
                if { $help !="" } {
                    set cl_serial_number -1
                }
            }
            if {[string length $a]!=[string length "serial-number"] && $help!=""} {
                set cl_serial_number ""
            }
            continue
        }
        puts "Syntax Error|invalid token:" 
        puts $a
        exit -1
    }
}

########### display online help (if asked for) #################
if { $argc > 0 } {
    set m [regexp -all "__cli_script.*help" [lindex $argv 0]]
    if { $m>0 } {
        # first level help: display script description
        if { [lindex $argv 0] == "__cli_script_help" } {
            puts "loads system/kickstart images and config file for POAP\n"
            exit 0
        }
        # argument help
        set argv_new [lreplace $argv 0 0]
        # dont count last arg if it was partial help (no-space-question-mark)
        if { [lindex $argv 0] == "__cli_script_args_help_partial" } {
          set argv_new [lreplace $argv_new [expr [llength $argv_new]-1] [expr [llength $argv_new]-1]]
        }
        parse_args $argv_new "help"
        if {$cl_serial_number== -1} {
            puts "WORD|Enter the serial number"
            exit 0
        }
        if { $cl_cdp_interface==-1 } {
            puts "WORD|Enter the CDP interface instance"
            exit 0
        }
        if { $cl_serial_number!="" } {
             puts "serial-number|The serial number to use for the config filename"
        }
        if { $cl_cdp_interface!="" } {
             puts "cdp-interface|The CDP interface to use for the config filename"
        }
        puts "<CR>|Run it (use static name for config file)"
        # we are done
        exit 0
   }
}

# *** now overwrite env vars with command line vars (if any given)

parse_args $argv
if { $cl_serial_number != ""} {
    set serial_number $cl_serial_number
    set config_file_type "serial_number"
}
if {$cl_cdp_interface != ""} { 
    set cdp_interface $cl_cdp_interface
    set config_file_type "location"
}

# figure out what kind of box we have (to download the correct images)
set ver [cli {show version | grep "cisco "}]
if [regexp (Nexus7.*) $ver] {
    set box "n7k"
    if [regexp ".*Unknown Module.*" $ver] {
        set box "titanium"
    }
} elseif [regexp (Nexus3.*) $ver] {
    set box "n3k"
} elseif {[regexp (Nexus.56.*) $ver] || [regexp (Nexus56.*) $ver] || [regexp (Nexus.6.*) $ver] || [regexp (Nexus6.*) $ver] || [regexp (Nexus.24Q.*) $ver] || [regexp (Nexus24Q.*) $ver] || [regexp (Nexus.48Q.*) $ver] || [regexp (Nexus48Q.*) $ver]} {
    set box "n6k"
} elseif {[regexp (Nexus.5.*) $ver] || [regexp (Nexus5.*) $ver]} {
    set box "n5k"
    if [regexp ".*Unknown Module.*" $ver] {
        set box "titanium"
    }
} elseif [regexp (9250*) $ver] {
    set box "m9250"
} elseif [regexp (9148s*) $ver] {
    set box "m9148s"
} elseif [regexp (9396s*) $ver] {
    set box "m9300"
} elseif [regexp (9513*) $ver] {
    set box "m9500"
} elseif [regexp (9706*) $ver] {
    set box "m9700"    
} else {
    set box "unknown"
}

# Get final image name based on actual box
# The variable box is the box platform, like n7k, n6k, titanium.
# This is to generate the kickstart or system image src variable names defined
# in the beginning of the file, e.g., n3k_system_image_src
# For different sup, e.g., sup1, sup2, assign the correct image name to image
# src variable
puts [format "Box is %s" $box]

if {$box == "unknown"} {
    exit -1
}

set system_image [format "%s_system_image_src" $box]
set system_image_src [set $system_image]

set kickstart_image [format "%s_kickstart_image_src" $box]
set kickstart_image_src [set $kickstart_image]

# images are copied to temporary location first (dont want to
# overwrite good images with bad ones).
set system_image_dst_tmp "bootflash:system.img.new"
set kickstart_image_dst_tmp "bootflash:kickstart.img.new"

# setup log file and associated utils
if {$now == ""} {
    set t [clock seconds]
    set now [clock format $t -format %m_%d_%H_%M]
}
catch {
    if {$poap_phase == "USB"} {
        set log_filename [format "%s_usb.%s" $log_filename $now]
    } else {
        set log_filename [format "%s.%s" $log_filename $now]
    }
} error
if {$error!=""} {
    #puts $error
}

set poap_log_file [open $log_filename "w+"]
puts $poap_log_file "POAP log file opened.\n"

proc poap_log {info} {
    global poap_log_file
    puts $poap_log_file $info
    puts $info
}

proc poap_log_close {} {
    global poap_log_file
    close $poap_log_file
}

proc abort_cleanup_exit {} {
    poap_log "INFO: cleaning up"
    cleanup_files
    poap_log_close
    exit -1
}

# some argument sanity checks:

if {$config_file_type == "serial_number" && $serial_number==""} {
    poap_log "ERR: serial-number required (to derive config name) but none give"
    exit -1
}

if {$config_file_type == "location" && $cdp_interface == ""} {
    poap_log "ERR: interface required (to derive config name) but none given"
    exit -1
}

# setup the cli session
cli "no terminal color"
cli "terminal dont-ask"
cli [format "terminal password %s" $password]

# Convert the CLI path to a unix path
proc to_unix_path { path } {
    regsub -all ":" $path "/" path
    return [format "/%s" $path]
}
set image_dir_dst_u [to_unix_path $image_dir_dst]

if {[file exists $image_dir_dst_u] != 1} {
    # If it doesn't exist create the directory
    file mkdir $image_dir_dst_u
}

# utility functions
proc run_cli { cmd } {
    poap_log [format "CLI : %s" $cmd]
    set output [cli $cmd]
    return $output
}

proc rm_rf { filename } {
    catch {
        if {file exists $filename } {
            run_cli [format "delete %s" $filename]
        }
    }
}

# signal handling
proc sig_handler_no_exit {signum frame} {
    poap_log "INFO: SIGTERM Handler while configuring boot variables"
}

proc sigterm_handler {signum frame} {
    poap_log "INFO: SIGTERM Handler" 
    abort_cleanup_exit
    exit -1
}

#signal trap sigterm_handler SIGTERM

# transfers file, return True on success; on error exits unless 'fatal' is False in which case we return False
proc doCopy {{protocol ""} {host ""} {source ""} {dest ""} {vrf "management"} {login_timeout 10} {username ""} {password ""} {phase ""} {fatal ""}} {
    
    rm_rf $dest 
    if {$phase == "USB"} {
        poap_log [format "INFO: Copying %s from USB" $source]
        set cmd [format "copy %s %s" $source $dest] 
    } else {
        set cmd [format "copy %s://%s@%s%s %s vrf %s" $protocol $username $host $source $dest $vrf]
    }

    catch {
        run_cli $cmd
    } error

    if {[file exists [to_unix_path $dest]]==0} {
        poap_log [format "WARN: Copy Failed: %s" $error] 
        if { $fatal==true } {
            poap_log "ERR : aborting"
            abort_cleanup_exit
            exit -1
        }
        return false
    }

    return true
}

proc ini2dict { filepath {separator =}} {
    
    if {$filepath ==""} {
        return ""
    }
    
    if {![file exists $filepath] || [catch { set fh [open $filepath r] } ] } {
         return ""
    }
    
    while {![chan eof $fh]} {
        gets $fh line
        
        if { [string length $line] < 2 } {
             continue
        }
        
        if { [regexp {^[[:blank:]]*\[{1}.*\]{1}} $line sect] } {
            set sect [string range $sect 1 end-1]
            continue
        }
        
        set seppoint [string first $separator $line]
        if { [string length $sect] && $seppoint > 1 } {
            set key [string range $line 0 [expr { $seppoint - 1 }]]
            set value [string range $line [expr { $seppoint + 1}] end ]
            dict set dic $sect $key $value
        }
    }
    
    close $fh
    return $dic
}


proc get_md5sum_src { file_name } {
    global protocol hostname md5_file_name_sr md5_file_name_dst vrf md5sum_timeout username password md5sum_ext_src poap_phase

    set md5_file_name_src [format "%s.%s"  $file_name $md5sum_ext_src]
    set l [split $md5_file_name_src "/"]
    set md5_file_name_dst [format "volatile:%s.poap_md5" [lindex $l end]]
    rm_rf $md5_file_name_dst

    set ret [doCopy $protocol $hostname $md5_file_name_src $md5_file_name_dst $vrf $md5sum_timeout $username $password $poap_phase false]
    if {$ret == true} {
        set sum [run_cli [format "show file %s | grep -v '^#' | head lines 1" $md5_file_name_dst]]
        set sum [string range $sum 7 end-1]
        poap_log [format "INFO: md5sum %s (.md5 file)" $sum]
        rm_rf $md5_file_name_dst
        return $sum
    }

    poap_log "INFO: No md5sum (.md5 file)"
    return ""
}

proc get_md5sum_dst { filename } {
    set sum [run_cli [format "show file %s md5sum" $filename]]
    set sum [string range $sum 0 end-1]
    poap_log [format "INFO: md5sum %s (recalculated)" $sum]
    return $sum  
}

proc check_md5sum {filename_src filename_dst lname} {
    set md5sum_src [get_md5sum_src $filename_src]
    # we found a .md5 file on the server
    if { $md5sum_src!=""} { 
            set md5sum_dst [get_md5sum_dst $filename_dst]
            if {$md5sum_dst != $md5sum_src} {
                poap_log [format "INFO: md5sum src: %s" $md5sum_src]	
                poap_log [format "INFO: md5sum dst: %s" $md5sum_dst]	
                poap_log [format "ERR : MD5 verification failed for %s! (%s)" $lname $filename_dst]
                abort_cleanup_exit
            }
    }
}

# Procedure to split config file using global information
proc splitConfigFile {} {
    global config_file_dst config_file_dst_first config_file_dst_second emptyFirstFile poap_script_log_handler
        set configFile [open [to_unix_path $config_file_dst] r]
        set configFile_first [open [to_unix_path $config_file_dst_first] w]
        set configFile_second [open [to_unix_path $config_file_dst_second] w]

        while {[gets $configFile line] >= 0} {
            if [expr {[string match "system vlan*" $line] || [string match "interface breakout*" $line] || [string match "hardware profile tcam*" $line] || [string match "*type fc" $line] || [string match "fabric-mode 40G" $line] || [string match "fabric-mode 10G" $line]}] {
                puts $configFile_first $line
                if {$emptyFirstFile == 1} {
                    set emptyFirstFile 0
                }
            } else {
                puts $configFile_second $line
            }
        }
        close $configFile
        file delete [to_unix_path $config_file_dst]
        set config_copied 0
        close $configFile_first
        if {$emptyFirstFile == 1} {
            file delete [to_unix_path $config_file_dst_first]
        }

        close $configFile_second
}

# Will run our CLI command to test MD5 checksum and if images are valid
# This check is also performed while setting the boot variables, but this is an
# additional check

proc get_version {msg} {
    set lines [split $msg "\n"]
    set ret {}
    foreach { line } $lines {
        set index [string first "MD5" $line]
        if { $index!=-1 } {
           lappend ret [lindex $line end] 
        }
        set index [string first "kickstart:" $line]
        if {$index!=-1} {
            set index [string first "version" $line]
            lappend ret [string range $line $index end]
            return $ret
        }
        set index [string first "system:" $line] 
        if {$index!=-1} {
            set index [string first "version" $line]
            lappend ret [string range $line $index end]
            return $ret
        }
    }
}

# Procedure to clean up the temporary file
proc cleanup_files { } {
    global config_file_dst config_db_file_dst config_file_dst_tmp system_image_dst kickstart_image_dst database_copied config_copied template_config_copied system_image_copied kickstart_image_copied generatedConfig emptyFirstFile config_file_dst_first config_file_dst_second
    poap_log "INFO: FINISH: Clean up files."
    if {$config_copied == 1} {
        run_cli [format "delete %s no" $config_file_dst]
    }
    if {$database_copied == 1} {
        run_cli [format "delete %s no" $config_db_file_dst]
    }
    if {$template_config_copied == 1} {
        run_cli [format "delete %s no" $config_file_dst_tmp]
    }
    if {$generatedConfig == 1} {
        run_cli [format "delete %s no" $config_file_dst_second]
        if {$emptyFirstFile == 0} {
            run_cli [format "delete %s no" $config_file_dst_first]
        }
    }
    if {$kickstart_image_copied == 1} {
        run_cli [format "delete %s no" $kickstart_image_dst]
    }
    if {$system_image_copied == 1} {
        run_cli [format "delete %s no" $system_image_dst]
    }
}

proc verify_images {} {
    global kickstart_image_dst system_image_dst

    set kick_cmd [format "show version image %s" $kickstart_image_dst]
    set sys_cmd [format "show version image %s" $system_image_dst]
    set kick_msg [run_cli $kick_cmd]
    set sys_msg [run_cli $sys_cmd]
    set kick_v [get_version $kick_msg]
    set sys_v [get_version $sys_msg]

    if {[lindex $kick_v 0] =="Passed" && [lindex $sys_v 0]=="Passed"} {
        # MD5 verification passed
        if {[lindex $kick_v 1]!=[lindex $sys_v 1]} {
            poap_log [format "ERR : Image version mismatch. (kickstart : %s) (system : %s)" [lindex $kick_v 1] [lindex $sys_v 1]]
            abort_cleanup_exit
        }
    } else {
        # HACK till "show version image" CLI is fixed.
        #poap_log "ERR : MD5 verification failed!"
        #poap_log [format "%s\n%s" $kick_msg $sys_msg]
        #abort_cleanup_exit
    }

    #poap_log [format "INFO: Verification passed. (kickstart : %s) (system : %s)" [lindex $sys_v 1] [lindex $sys_v 1]]

    return true
}

# get config file from server
proc get_config {} {
    global protocol hostname config_file_src config_file_dst vrf config_timeout username password config_path config_copied generatedConfig poap_phase
    poap_log "INFO: Fetch Configuration File:"
    if {$poap_phase == "USB"} {
        set config_file_src [format "usb1:%s" $config_file_src]
    } else {
        set config_file_src [format "%s%s" $config_path $config_file_src]
    }

    poap_log [format "INFO: Copying %s " $config_file_src] 
    set ret [doCopy $protocol $hostname $config_file_src $config_file_dst $vrf $config_timeout $username $password $poap_phase true]
    if {$ret == false} {
        poap_log "ERR: Unable to Copy Configuration File"
    } else {
        poap_log "INFO: Completed Copy of Configuration File" 
        set config_copied 1
    }

    # get file's md5 from server (if any) and verify it, failure is fatal (exit)
    poap_log "INFO: Check md5 of Configuration File"
    check_md5sum $config_file_src $config_file_dst "config file"

    poap_log "INFO: Split Config invoked ..."
    splitConfigFile
    set generatedConfig 1
}

# get system image file from server
proc get_system_image {} { 
    global protocol hostname system_image_src system_image_dst_tmp system_image_dst vrf system_timeout username password image_dir_src system_image_copied poap_phase

    poap_log "INFO: Starting Copy of System Image"
    if {$poap_phase == "USB"} {
        set system_image_src [format "usb1:%s" $system_image_src]
    } else {
        set system_image_src [format "%s%s" $image_dir_src $system_image_src]
    }

    if {[file exists [to_unix_path $system_image_dst]]} {
        poap_log "INFO: Deleting old version of $system_image_dst"
        file delete [to_unix_path $system_image_dst]
    }

    poap_log [format "INFO: Copying %s " $system_image_src] 
    set ret [doCopy $protocol $hostname $system_image_src $system_image_dst $vrf $system_timeout $username $password $poap_phase true] 
    if {$ret == false} {
        poap_log "ERR: Unable to Copy System Image"
    } else {
        poap_log "INFO: Copy of System Image Successful"
    }

    # get file's md5 from server (if any) and verify it
    poap_log "INFO: Check md5 of System Image"
    check_md5sum $system_image_src $system_image_dst "system image"

    #Now that system image has been copied successfully
    #delete old system image and move tmp image to system image 
  #  set tmp [to_unix_path $system_image_dst_tmp]
   # if {[file exists [to_unix_path $system_image_dst]]} {
    #    poap_log "INFO: Deleting old version of $system_image_dst"
     #   file delete [to_unix_path $system_image_dst]
   # }
    #poap_log [format "INFO: Copy %s to %s" $system_image_dst_tmp $system_image_dst]
    #run_cli "copy $system_image_dst_tmp $system_image_dst"
    #file delete $tmp

    set system_image_copied 1
    
}

# get kickstart image file from server
proc get_kickstart_image {} {
    global protocol hostname kickstart_image_src kickstart_image_dst_tmp kickstart_image_dst vrf kickstart_timeout username password image_dir_src kickstart_image_copied poap_phase

    poap_log "INFO: Starting Copy of Kickstart Image"
    if {$poap_phase == "USB"} {
        set kickstart_image_src [format "usb1:%s" $kickstart_image_src]
    } else {
        set kickstart_image_src [format "%s%s" $image_dir_src $kickstart_image_src]
    }

    if {[file exists [to_unix_path $kickstart_image_dst]]} {
        poap_log "INFO: Deleting old version of $kickstart_image_dst"
        file delete [to_unix_path $kickstart_image_dst]
    }

    set ret [ doCopy $protocol $hostname $kickstart_image_src $kickstart_image_dst $vrf $kickstart_timeout $username $password $poap_phase true] 
    if {$ret == false } {
        poap_log "ERR: Unable to Copy Kickstart Image"
        abort_cleanup_exit
    } else {
        poap_log "INFO: Copy of Kickstart Image Successful"
    }
    
    # get file's md5 from server (if any) and verify it, failure is fatal (exit)
    poap_log "INFO: Check MD5 of Kickstart Image"
    check_md5sum $kickstart_image_src $kickstart_image_dst "kickstart image"

    #Now that kickstart image has been copied successfully
    #delete old kickstart image and move tmp image to kickstart image
 #   set tmp [to_unix_path $kickstart_image_dst_tmp]
   # if {[file exists [to_unix_path $kickstart_image_dst]]} {
    #    poap_log "INFO: Deleting old version of $kickstart_image_dst"
     #   file delete [to_unix_path $kickstart_image_dst]
 #   }
  #  poap_log [format "INFO: Copy %s to %s" $kickstart_image_dst_tmp $kickstart_image_dst]
   # run_cli "copy $kickstart_image_dst_tmp $kickstart_image_dst"
    #file delete $tmp

    set kickstart_image_copied 1

}

proc wait_box_online {} {
    while {1} {
        set r [run_cli "show system internal ascii-cfg event-history | grep BOX_ONLINE"]
        # TBD: Fix this
        if {[lsearch $r "SUCCESS"] == -1} { 
            poap_log "success"
            break 
        }
        after 5000
        poap_log "INFO: Waiting for box online..."
    }
}

# install (make persistent) images and config 
proc install_it {} { 
    global kickstart_image_dst system_image_dst config_file_dst config_file_dst_first config_file_dst_second emptyFirstFile box kickstart_image_copied system_image_copied 

    set timeout -1
    wait_box_online
    poap_log "INFO: Setting the boot variables"

    set r1 [run_cli [format "config terminal ; boot kickstart %s" $kickstart_image_dst]]
    set r2 [run_cli [format "config terminal ; boot system %s" $system_image_dst]]
    set x 1
    while {$x} {
        set r3 [run_cli "copy running-config startup-config"]
        poap_log "## $r3"

        if {[lsearch $r3 "aborted:"] != -1} {
            poap_log "INFO: Wait 10 sec and retry"
            after 10000
        } elseif {[lsearch $r3 "complete,"] != -1 || [lsearch $r3 "complete."] != -1} {
            poap_log "success copy running-config to startup-config"
            set x 0
        } else {
            poap_log "command failed. Abort POAP."
            abort_cleanup_exit
        }
    }
    if {$emptyFirstFile == 0} { 
        set r4 [run_cli [format "copy %s scheduled-config" $config_file_dst_first]]
        if { $box == "titanium"} {
            if {[lsearch $r4 "complete."]==-1} {
                poap_log "ERR: copy 1st config to scheduled config Failed!"
                abort_cleanup_exit
            }
        } else {
            if {[lsearch $r4 "complete."]==-1} {
                poap_log "ERR: copy 1st config to scheduled config Failed!"
                abort_cleanup_exit
            }
        }
        poap_log "### Copying the first scheduled cfg done ###"
    }
    set r5 [run_cli [format "copy %s scheduled-config" $config_file_dst_second]]
    if { $box == "titanium"} {
        if {[lsearch $r1 "Failed"]!=-1 || [lsearch $r2 "Failed"]!=-1 ||
            [lsearch $r3 "complete."]==-1 || [lsearch $r5 "complete."]==-1} {
            poap_log "ERR : setting bootvars or copy run start failed!"
            abort_cleanup_exit
        }
    } else {
        if {[lsearch $r1 "Failed"]!=-1 || [lsearch $r2 "Failed"]!=-1 ||
            [lsearch $r3 "complete."]==-1 || [lsearch $r5 "complete."]==-1} {
            poap_log "ERR : setting bootvars or copy run start failed!"
            abort_cleanup_exit
        }
    }
	poap_log "INFO: Configuration successful"
    # If we are at this stage,it means that there is no error. We dont want to
    # delete the system/kickstart images that were downloaded
    set kickstart_image_copied 0
    set system_image_copied 0
}

# Verify if free space is available to download config, kickstart and system images
proc verify_freespace {} { 
    global required_space

    poap_log "INFO: Verifying Free Space:"

    set freespace [run_cli "dir bootflash: | last 3 | grep free | tr -d -c 0-9"]
    set freespace [expr $freespace / 1024]

    poap_log [format "INFO: free space is %s kB"  $freespace]

    if {$required_space > $freespace} {
        poap_log "ERR : Not enough space to copy the config, kickstart image and system image, aborting!"
        abort_cleanup_exit
    }
}

# figure out config filename to download based on serial-number
proc set_config_file_src_serial_number {} { 
    global config_file_src serial_number
    set config_file_src [format "conf_%s.cfg" $serial_number]
    poap_log [format "INFO: Selected config filename (serial-nb) : %s" $config_file_src]
}

# figure out config filename to download based on cdp neighbor info
# sample output:
#   switch# show cdp neig
#   Capability Codes: R - Router, T - Trans-Bridge, B - Source-Route-Bridge
#                     S - Switch, H - Host, I - IGMP, r - Repeater,
#                     V - VoIP-Phone, D - Remotely-Managed-Device,
#                     s - Supports-STP-Dispute, M - Two-port Mac Relay
#
#   Device ID              Local Intrfce   Hldtme  Capability  Platform      Port ID
#   Switch                 mgmt0           148     S I         WS-C2960G-24T Gig0/2
#   switch(Nexus-Switch)   Eth1/1          150     R S I s     Nexus-Switch  Eth2/1
#   switch(Nexus-Switch)   Eth1/2          150     R S I s     Nexus-Switch  Eth2/2
# in xml:
#   <ROW_cdp_neighbor_brief_info>
#    <ifindex>83886080</ifindex>
#    <device_id>Switch</device_id>
#    <intf_id>mgmt0</intf_id>
#    <ttl>137</ttl>
#    <capability>switch</capability>
#    <capability>IGMP_cnd_filtering</capability>
#    <platform_id>cisco WS-C2960G-24TC-L</platform_id>
#    <port_id>GigabitEthernet0/4</port_id>
#   </ROW_cdp_neighbor_brief_info>

###@@@ This needs to be worked on and checked @@@###
proc set_config_file_src_location {} {
    global cdp_interface config_file_src
    set cmd [format "show cdp neighbors interface %s" $cdp_interface]
    poap_log [format "CLI: %s" $cmd]
    set r [ run_cli $cmd]
    if { [lsearch $r "Capability"]==-1 } {
        poap_log $r
        poap_log [format "ERR: canot get neighbor info on %s" $cdp_interface]
        exit -1
    }
    set l [lindex [split $r "\n"] 7]
    set switchName [lindex $l 0]
    set intfName [lindex $l end]
    if { $switchName=="" || $intfName=="" } {
        poap_log [format "ERR: unexpected 'show cdp neigbhor' output: %s" $r]
        exit -1
    }
    set neighbor [format "%s_%s" $switchName $intfName]
    regsub -all "/" $neighbor "_" neighbor
    set config_file_src [format "conf_%s.cfg" $neighbor]
    poap_log [format "INFO: Selected config filename (cdp-neighbor) : %s" $config_file_src]
}

# Procedure to set config_file based on switch interface MAC
proc set_config_file_src_mac {} {
    global config_file_src poap_script_log_handler env
    if [info exists env(POAP_MAC)] {
        poap_log "INFO: Interface MAC: $env(POAP_MAC)"
        set config_file_src [format "conf_%s.cfg" $env(POAP_MAC)]
    } else {
        poap_log "WARN: MAC info Missing, falling back to static mode"
    }
    poap_log "INFO: Selected conf file name : $config_file_src"
}

proc set_config_file_src_hostname {} {
        global config_file_src poap_script_log_handler env
        if [info exists env(POAP_HOST_NAME)] {
                poap_log "INFO: Using Host Name: $env(POAP_HOST_NAME)"
                set config_file_src [format "conf_%s.cfg" $env(POAP_HOST_NAME)]
        } else {
                poap_log "WARN: Host Name Missing, falling back to static mode"
        }
        poap_log "INFO: Selected conf file name : $config_file_src"
}


# set complete name of config_file_src based on serial-number/interface (add extension)

if {$config_file_type == "location"} { 
    #set source config file based on location
    set_config_file_src_location
} elseif {$config_file_type == "serial_number"} {
    #set source config file based on switch's serial number
    set_config_file_src_serial_number
} elseif {$config_file_type == "hostname"} {
    set_config_file_src_hostname
} elseif {$config_file_type == "mac"} {
    set_config_file_src_mac
} else {
    poap_log "Error: Enter the valid config file type"
}

# Execute the commands
verify_freespace
get_config
get_kickstart_image
get_system_image
verify_images
# Don't let people abort the final stage that concretize everything
install_it
cleanup_files
poap_log_close
exit 0

