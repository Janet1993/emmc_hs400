@echo off
set xv_path=G:\\Xilinx\\Vivado\\2015.4\\bin
call %xv_path%/xsim Test_eMMC_Controller_tb_func_impl -key {Post-Implementation:sim_1:Functional:Test_eMMC_Controller_tb} -tclbatch Test_eMMC_Controller_tb.tcl -view D:/VivadoProjects/eMMC_Controller/eMMC_Controller.sim/behav_waveform/Test_eMMC_Controller_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
