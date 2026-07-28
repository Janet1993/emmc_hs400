-- Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2015.4 (win64) Build 1412921 Wed Nov 18 09:43:45 MST 2015
-- Date        : Wed Oct 19 19:03:55 2016
-- Host        : WuLizhou-PC running 64-bit Service Pack 1  (build 7601)
-- Command     : write_vhdl -force -mode synth_stub
--               D:/VivadoProjects/eMMC_Controller_4.6.1_tuning.xpr/eMMC_Controller/eMMC_Controller.srcs/sources_1/ip/clk_divided/clk_divided_stub.vhdl
-- Design      : clk_divided
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_divided is
  Port ( 
    clk_in1 : in STD_LOGIC;
    clk_200M : out STD_LOGIC;
    clk_200M_reverse : out STD_LOGIC;
    clk_200M_capture : out STD_LOGIC;
    clk_20M : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC
  );

end clk_divided;

architecture stub of clk_divided is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_in1,clk_200M,clk_200M_reverse,clk_200M_capture,clk_20M,reset,locked";
begin
end;
