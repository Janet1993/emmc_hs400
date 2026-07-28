// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.4 (win64) Build 1412921 Wed Nov 18 09:43:45 MST 2015
// Date        : Wed Oct 19 19:03:55 2016
// Host        : WuLizhou-PC running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               D:/VivadoProjects/eMMC_Controller_4.6.1_tuning.xpr/eMMC_Controller/eMMC_Controller.srcs/sources_1/ip/clk_divided/clk_divided_stub.v
// Design      : clk_divided
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_divided(clk_in1, clk_200M, clk_200M_reverse, clk_200M_capture, clk_20M, reset, locked)
/* synthesis syn_black_box black_box_pad_pin="clk_in1,clk_200M,clk_200M_reverse,clk_200M_capture,clk_20M,reset,locked" */;
  input clk_in1;
  output clk_200M;
  output clk_200M_reverse;
  output clk_200M_capture;
  output clk_20M;
  input reset;
  output locked;
endmodule
