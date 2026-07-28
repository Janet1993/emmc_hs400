@echo off
set xv_path=G:\\Xilinx\\Vivado\\2015.4\\bin
call %xv_path%/xelab  -wto 0ae2e975806e42f58cbca616d740b948 -m64 --debug typical --relax --mt 2 -L fifo_generator_v13_0_1 -L xil_defaultlib -L blk_mem_gen_v8_3_1 -L unisims_ver -L unimacro_ver -L secureip --snapshot Test_eMMC_Controller_tb_behav xil_defaultlib.Test_eMMC_Controller_tb xil_defaultlib.glbl -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
