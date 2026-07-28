`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/17 16:07:33
// Design Name: 
// Module Name: CRC16_Check
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


module CRC16_Check(
input        clk,
input        BITVAL,                          // Next input bit
input        Enable,
input        rst,                            // Init CRC value
output reg [15:0] CRC                             // Current output CRC value
);

always @(posedge clk ) begin
   if (rst) begin
      CRC <= 16'h0;                                  // Init before calculation
      end
   else begin
      if(Enable==1'b1) begin
      CRC[15] <= CRC[14];
      CRC[14] <= CRC[13];
      CRC[13] <= CRC[12];
      CRC[12] <= CRC[11] ^ CRC[15];
      CRC[11] <= CRC[10];
      CRC[10] <= CRC[9];
      CRC[9]  <= CRC[8];
      CRC[8]  <= CRC[7];
      CRC[7]  <= CRC[6];
      CRC[6]  <= CRC[5];
      CRC[5]  <= CRC[4] ^ CRC[15];
      CRC[4]  <= CRC[3];
      CRC[3]  <= CRC[2];
      CRC[2]  <= CRC[1];
      CRC[1]  <= CRC[0];
      CRC[0]  <=  BITVAL^CRC[15];
      end
      else
      begin
        CRC<=CRC;
      end
   end
end
endmodule
