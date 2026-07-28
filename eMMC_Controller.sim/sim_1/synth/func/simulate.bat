@echo off
set xv_path=G:\\Xilinx\\Vivado\\2015.4\\bin
call %xv_path%/xsim Test_eMMC_Controller_tb_func_synth -key {Post-Synthesis:sim_1:Functional:Test_eMMC_Controller_tb} -tclbatch Test_eMMC_Controller_tb.tcl -view D:/VivadoProjects/eMMC_Controller_4.5.xpr/eMMC_Controller/eMMC_Controller.srcs/sim_1/imports/eMMC_Controller/eMMC_Controller.sim/behav_waveform/Test_eMMC_Controller_tb_behav_HS400E.wcfg -view D:/VivadoProjects/eMMC_Controller_4.5.xpr/eMMC_Controller/eMMC_Controller.srcs/sim_1/imports/eMMC_Controller/eMMC_Controller.sim/behav_waveform/CRC16_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
