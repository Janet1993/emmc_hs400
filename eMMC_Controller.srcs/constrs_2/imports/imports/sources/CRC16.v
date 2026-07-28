`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/16 10:15:25
// Design Name: 
// Module Name: CRC16
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
module CRC16(
   input        clk,
   input        BITVAL,                          // Next input bit
   input        Enable,
   input        rst,                            // Init CRC value
   output reg [15:0] CRC                             // Current output CRC value
);
   wire         inv;
   
   assign inv = BITVAL ^ CRC[15];                   // XOR required?
   
   always @(posedge clk ) begin
      if (rst) begin
         CRC <= 16'h0;                                  // Init before calculation
         end
      else begin
         if(Enable==1'b1) begin
         CRC[15] <= CRC[14];
         CRC[14] <= CRC[13];
         CRC[13] <= CRC[12];
         CRC[12] <= CRC[11] ^ inv;
         CRC[11] <= CRC[10];
         CRC[10] <= CRC[9];
         CRC[9]  <= CRC[8];
         CRC[8]  <= CRC[7];
         CRC[7]  <= CRC[6];
         CRC[6]  <= CRC[5];
         CRC[5]  <= CRC[4] ^ inv;
         CRC[4]  <= CRC[3];
         CRC[3]  <= CRC[2];
         CRC[2]  <= CRC[1];
         CRC[1]  <= CRC[0];
         CRC[0]  <= inv;
         end
         else
         begin
           CRC<=CRC;
         end
      end
  end
   
endmodule