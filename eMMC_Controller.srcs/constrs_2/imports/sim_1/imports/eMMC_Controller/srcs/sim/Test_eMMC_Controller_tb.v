`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/18 16:46:23
// Design Name: 
// Module Name: Test_eMMC_Controller_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Test_eMMC_Controller_tb;
reg clk;
reg clk_400k;
reg sysrst;

wire heartbeat;



        initial begin
        clk=1'b0;
        clk_400k=1'b0;
        sysrst=1'b0;
        #6000;
        sysrst=1'b1;
        #200;
        sysrst=1'b0;

        end

Test_eMMC_Controller eMMC_Controller(
                   .sysclk_100M(clk),
                   .sysrst(sysrst),
                   .heartbeat(heartbeat),
                   // Device interface
                   .device_clk(),
                   .rst_n(),
                   .device_data_strobe(),
                   .device_data_bus(),
                   .device_cmd()
                    );
            
always # 5 clk=~clk; 
always #1250 clk_400k=~clk_400k; 
endmodule
