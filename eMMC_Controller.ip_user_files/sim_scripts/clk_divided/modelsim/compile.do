vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vlog -work xil_defaultlib -64 -incr \
"../../../../eMMC_Controller.srcs/sources_1/ip/clk_divided/clk_divided_clk_wiz.v" \
"../../../../eMMC_Controller.srcs/sources_1/ip/clk_divided/clk_divided.v" \


vlog -work xil_defaultlib "glbl.v"

