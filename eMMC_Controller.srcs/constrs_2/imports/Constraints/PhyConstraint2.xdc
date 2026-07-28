
set_property IOSTANDARD LVCMOS18 [get_ports device_clk]
set_property IOSTANDARD LVCMOS18 [get_ports device_cmd]
set_property IOSTANDARD LVCMOS18 [get_ports device_data_strobe]
set_property IOSTANDARD LVCMOS18 [get_ports rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sysrst]
set_property IOSTANDARD LVCMOS18 [get_ports {device_data_bus[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {device_data_bus[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {device_data_bus[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {device_data_bus[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {device_data_bus[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {device_data_bus[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {device_data_bus[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {device_data_bus[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports sysclk_100M]
set_property IOSTANDARD LVCMOS18 [get_ports heartbeat]

set_property PACKAGE_PIN P20 [get_ports {device_data_bus[0]}]
set_property PACKAGE_PIN P21 [get_ports {device_data_bus[1]}]
set_property PACKAGE_PIN J20 [get_ports {device_data_bus[2]}]
set_property PACKAGE_PIN K21 [get_ports {device_data_bus[3]}]
set_property PACKAGE_PIN K19 [get_ports {device_data_bus[4]}]
set_property PACKAGE_PIN K20 [get_ports {device_data_bus[5]}]
set_property PACKAGE_PIN J18 [get_ports {device_data_bus[6]}]
set_property PACKAGE_PIN K18 [get_ports {device_data_bus[7]}]
set_property PACKAGE_PIN N19 [get_ports device_data_strobe]
set_property PACKAGE_PIN N20 [get_ports rst_n]
set_property PACKAGE_PIN L17 [get_ports device_clk]
set_property PACKAGE_PIN M17 [get_ports device_cmd]
set_property PACKAGE_PIN T22 [get_ports heartbeat]
set_property PACKAGE_PIN T18 [get_ports sysrst]
set_property PACKAGE_PIN Y9 [get_ports sysclk_100M]
















set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[14]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[10]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[9]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[8]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[7]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[2]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[3]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[13]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[11]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[12]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[0]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[4]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[6]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[5]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[15]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_bus_out_reg_n_0_[1]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[7]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[11]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[0]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[4]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[5]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[3]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[8]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[6]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[2]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[1]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[13]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[14]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[15]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[10]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[12]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_data_final[9]}]
set_property MARK_DEBUG true [get_nets eMMC_controller_inst0/fifo_wr_en]
connect_debug_port u_ila_0/probe7 [get_nets [list eMMC_controller_inst0/fifo_wr_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 16 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {eMMC_controller_inst0/rd_data_final[0]} {eMMC_controller_inst0/rd_data_final[1]} {eMMC_controller_inst0/rd_data_final[2]} {eMMC_controller_inst0/rd_data_final[3]} {eMMC_controller_inst0/rd_data_final[4]} {eMMC_controller_inst0/rd_data_final[5]} {eMMC_controller_inst0/rd_data_final[6]} {eMMC_controller_inst0/rd_data_final[7]} {eMMC_controller_inst0/rd_data_final[8]} {eMMC_controller_inst0/rd_data_final[9]} {eMMC_controller_inst0/rd_data_final[10]} {eMMC_controller_inst0/rd_data_final[11]} {eMMC_controller_inst0/rd_data_final[12]} {eMMC_controller_inst0/rd_data_final[13]} {eMMC_controller_inst0/rd_data_final[14]} {eMMC_controller_inst0/rd_data_final[15]}]]

set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/Fifo_bit_counter_reg__0[6]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/Fifo_bit_counter_reg__0[4]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/Fifo_bit_counter_reg__0[0]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/Fifo_bit_counter_reg__0[8]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/Fifo_bit_counter_reg__0[3]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/Fifo_bit_counter_reg__0[5]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/Fifo_bit_counter_reg__0[7]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/Fifo_bit_counter_reg__0[1]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/Fifo_bit_counter_reg__0[2]}]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 9 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {eMMC_controller_inst0/Fifo_bit_counter_reg__0[0]} {eMMC_controller_inst0/Fifo_bit_counter_reg__0[1]} {eMMC_controller_inst0/Fifo_bit_counter_reg__0[2]} {eMMC_controller_inst0/Fifo_bit_counter_reg__0[3]} {eMMC_controller_inst0/Fifo_bit_counter_reg__0[4]} {eMMC_controller_inst0/Fifo_bit_counter_reg__0[5]} {eMMC_controller_inst0/Fifo_bit_counter_reg__0[6]} {eMMC_controller_inst0/Fifo_bit_counter_reg__0[7]} {eMMC_controller_inst0/Fifo_bit_counter_reg__0[8]}]]


set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Data_Arriving]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[63]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[61]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[62]}]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 3 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[62]} {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[63]} {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[61]}]]

set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[0]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[1]}]
set_property MARK_DEBUG true [get_nets {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[2]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/rd_cmd_temp[2]_i_1_n_0}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/rd_cmd_temp[1]_i_1_n_0}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/rd_cmd_temp[0]_i_1_n_0}]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/fifo_wr_start]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 3 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[2]} {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[1]} {eMMC_controller_inst0/rd_cmd_temp_reg_n_0_[0]}]]

set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/fifo_wr_end_i_1_n_0]

set_property MARK_DEBUG true [get_nets eMMC_controller_inst0/fifo_MUX]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list eMMC_controller_inst0/fifo_MUX]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_200M_capture]
