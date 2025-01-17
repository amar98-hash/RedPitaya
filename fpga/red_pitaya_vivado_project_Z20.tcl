################################################################################
# Vivado tcl script for building RedPitaya FPGA in non project mode
#
# Usage:
# vivado -mode batch -source red_pitaya_vivado_project_Z20.tcl -tclargs projectname
################################################################################

set prj_name [lindex $argv 0]
puts "Project name: $prj_name"
cd C:/Users/Amar/Documents/Xilinx_workspace/RedPitaya-master/fpga/$prj_name
#cd prj/$::argv 0

################################################################################
# define paths
################################################################################


set path_brd C:/Users/Amar/Documents/Xilinx_workspace/RedPitaya-master/fpga/brd
set path_rtl C:/Users/Amar/Documents/Xilinx_workspace/RedPitaya-master/fpga/rtl
set path_ip  C:/Users/Amar/Documents/Xilinx_workspace/RedPitaya-master/fpga/prj/v0.94_250/ip
set path_bd  project/redpitaya.srcs/sources_1/bd/system/hdl
set path_sdc C:/Users/Amar/Documents/Xilinx_workspace/RedPitaya-master/fpga/sdc
set path_sdc_prj sdc


################################################################################
# list board files
################################################################################

set_param board.repoPaths [list $path_brd]

################################################################################
# setup an in memory project
################################################################################

set part xc7z020clg400-1

create_project -part $part -force redpitaya ./project

################################################################################
# create PS BD (processing system block design)
################################################################################

# file was created from GUI using "write_bd_tcl -force ip/systemZ20.tcl"
# create PS BD
source                            $path_ip/systemZ20.tcl

# generate SDK files
generate_target all [get_files    system.bd]

################################################################################
# read files:
# 1. RTL design sources
# 2. IP database files
# 3. constraints
################################################################################

add_files                         $path_rtl
add_files                         $path_rtl
add_files                         $path_bd

add_files -fileset constrs_1      $path_sdc/red_pitaya.xdc
add_files -fileset constrs_1      $path_sdc_prj/red_pitaya.xdc

################################################################################
# start gui
################################################################################

import_files -force

set_property top red_pitaya_top_Z20 [current_fileset]

update_compile_order -fileset sources_1

