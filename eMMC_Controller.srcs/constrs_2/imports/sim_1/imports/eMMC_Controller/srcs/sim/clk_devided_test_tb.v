`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/18 10:56:36
// Design Name: 
// Module Name: clk_devided_test_tb
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


module clk_devided_test_tb;
reg clk=1'b0;
/*
reg [1:0] cnt=2'b0;
reg clk1x_en=1'b0;

always @ (posedge clk)
begin
cnt <= cnt +1'b1;
if(cnt ==2'b01)
         clk1x_en <= 1'b1;
     else
         clk1x_en <= 1'b0;

end
*/


always # 5 clk=~clk; 
endmodule
