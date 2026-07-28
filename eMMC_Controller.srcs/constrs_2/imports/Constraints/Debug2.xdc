create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 16384 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_200M_capture]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 5 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {eMMC_controller_inst0/Steps_Curr_State[0]} {eMMC_controller_inst0/Steps_Curr_State[1]} {eMMC_controller_inst0/Steps_Curr_State[2]} {eMMC_controller_inst0/Steps_Curr_State[3]} {eMMC_controller_inst0/Steps_Curr_State[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 8 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {eMMC_controller_inst0/Device_data_temp_n[0]} {eMMC_controller_inst0/Device_data_temp_n[1]} {eMMC_controller_inst0/Device_data_temp_n[2]} {eMMC_controller_inst0/Device_data_temp_n[3]} {eMMC_controller_inst0/Device_data_temp_n[4]} {eMMC_controller_inst0/Device_data_temp_n[5]} {eMMC_controller_inst0/Device_data_temp_n[6]} {eMMC_controller_inst0/Device_data_temp_n[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 5 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {eMMC_controller_inst0/HS400E_Curr_State[0]} {eMMC_controller_inst0/HS400E_Curr_State[1]} {eMMC_controller_inst0/HS400E_Curr_State[2]} {eMMC_controller_inst0/HS400E_Curr_State[3]} {eMMC_controller_inst0/HS400E_Curr_State[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {eMMC_controller_inst0/Device_data_temp_p[0]} {eMMC_controller_inst0/Device_data_temp_p[1]} {eMMC_controller_inst0/Device_data_temp_p[2]} {eMMC_controller_inst0/Device_data_temp_p[3]} {eMMC_controller_inst0/Device_data_temp_p[4]} {eMMC_controller_inst0/Device_data_temp_p[5]} {eMMC_controller_inst0/Device_data_temp_p[6]} {eMMC_controller_inst0/Device_data_temp_p[7]}]]



set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Device_data_bus_out_DDR_7]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Device_data_bus_out_DDR_1]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Device_data_bus_out_DDR_0]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Device_data_bus_out_DDR_2]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Device_data_bus_out_DDR_3]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Device_data_bus_out_DDR_4]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Device_data_bus_out_DDR_5]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Device_data_bus_out_DDR_6]

set_property MARK_DEBUG true [get_nets eMMC_controller_inst0/rd_buf_wr_en]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list eMMC_controller_inst0/rd_buf_wr_en]]


set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[0]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[10]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[11]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[12]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[13]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[14]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[15]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[1]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[2]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[3]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[4]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[5]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[6]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[7]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[8]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Device_data_temp[9]}]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Response_received_reg_n_0]


set_property MARK_DEBUG true [get_nets eMMC_controller_inst0/crc16_check_result]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/clk_counter_reg__0[5]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/clk_counter_reg__1[0]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/clk_counter_reg__1[2]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/clk_counter_reg__1[3]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/clk_counter_reg__1[4]}]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/Response_Arriving_reg_n_0]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Resp_bit_counter_reg__0[0]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Resp_bit_counter_reg__0[7]}]
set_property MARK_DEBUG false [get_nets eMMC_controller_inst0/clk_400K_en]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/clk_counter_reg__1[1]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Resp_bit_counter_reg__0[1]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Resp_bit_counter_reg__0[2]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Resp_bit_counter_reg__0[3]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Resp_bit_counter_reg__0[4]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Resp_bit_counter_reg__0[5]}]
set_property MARK_DEBUG false [get_nets {eMMC_controller_inst0/Resp_bit_counter_reg__0[6]}]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list eMMC_controller_inst0/crc16_check_result]]










