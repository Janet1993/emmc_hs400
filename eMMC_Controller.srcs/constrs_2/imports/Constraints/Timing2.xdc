#create_clock -period 10.000 -name sysclk_100M -waveform {0.000 5.000} [get_ports sysclk_100M]

create_generated_clock -name eMMC_controller_inst0/clk_400K -source [get_pins eMMC_controller_inst0/clk_200M] -divide_by 64 [get_pins eMMC_controller_inst0/clk_400K_reg/Q]

#State that device_clk_400K and device_clk_200M are logically exclusive, which is muxed by a BUFGMUX.
create_generated_clock -name device_clk_400K -source [get_pins eMMC_controller_inst0/BUFGMUX_CTRL_inst/I0] -divide_by 1 [get_pins eMMC_controller_inst0/BUFGMUX_CTRL_inst/O]
create_generated_clock -name device_clk_200M -source [get_pins eMMC_controller_inst0/BUFGMUX_CTRL_inst/I1] -divide_by 1 -add -master_clock clk_200M_clk_divided [get_pins eMMC_controller_inst0/BUFGMUX_CTRL_inst/O]
set_clock_groups -logically_exclusive -group [get_clocks device_clk_400K] -group [get_clocks device_clk_200M]

#The following two are forwarded clocks for source sync. interface. of eMMC device
create_generated_clock -name fwdClk_200M -source [get_pins eMMC_controller_inst0/ODDR_inst/C] -multiply_by 1 -invert -add -master_clock device_clk_200M [get_pins eMMC_controller_inst0/device_clk]
create_generated_clock -name fwdClk_400K -source [get_pins eMMC_controller_inst0/ODDR_inst/C] -multiply_by 1 -invert -add -master_clock device_clk_400K [get_pins eMMC_controller_inst0/device_clk]

#set_multicycle_path -setup -end -from [get_clocks clk_200M_clk_divided] -to [get_clocks fwdClk_200M] 2

set_output_delay -clock [get_clocks fwdClk_200M] 2.500 [get_ports device_cmd]

#set_output_delay -clock [get_clocks clk_200M_clk_divided] -max 1.500 [get_ports {device_data_bus[0]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -min 1.000 [get_ports {device_data_bus[0]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -max -add_delay 1.500 [get_ports {device_data_bus[0]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -min -add_delay 1.000 [get_ports {device_data_bus[0]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -max 1.500 [get_ports {device_data_bus[1]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -min 1.000 [get_ports {device_data_bus[1]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -max -add_delay 1.500 [get_ports {device_data_bus[1]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -min -add_delay 1.000 [get_ports {device_data_bus[1]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -max 1.500 [get_ports {device_data_bus[2]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -min 1.000 [get_ports {device_data_bus[2]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -max -add_delay 1.500 [get_ports {device_data_bus[2]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -min -add_delay 1.000 [get_ports {device_data_bus[2]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -max 1.500 [get_ports {device_data_bus[3]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -min 1.000 [get_ports {device_data_bus[3]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -max -add_delay 1.500 [get_ports {device_data_bus[3]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -min -add_delay 1.000 [get_ports {device_data_bus[3]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -max 1.500 [get_ports {device_data_bus[4]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -min 1.000 [get_ports {device_data_bus[4]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -max -add_delay 1.500 [get_ports {device_data_bus[4]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -min -add_delay 1.000 [get_ports {device_data_bus[4]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -max 1.500 [get_ports {device_data_bus[5]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -min 1.000 [get_ports {device_data_bus[5]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -max -add_delay 1.500 [get_ports {device_data_bus[5]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -min -add_delay 1.000 [get_ports {device_data_bus[5]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -max 1.500 [get_ports {device_data_bus[6]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -min 1.000 [get_ports {device_data_bus[6]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -max -add_delay 1.500 [get_ports {device_data_bus[6]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -min -add_delay 1.000 [get_ports {device_data_bus[6]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -max 1.500 [get_ports {device_data_bus[7]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -min 1.000 [get_ports {device_data_bus[7]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -max -add_delay 1.500 [get_ports {device_data_bus[7]}]
#set_output_delay -clock [get_clocks clk_200M_clk_divided] -clock_fall -min -add_delay 1.000 [get_ports {device_data_bus[7]}]




