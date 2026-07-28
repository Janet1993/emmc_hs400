`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/17 15:12:34
// Design Name: 
// Module Name: CRC7_Check
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


module CRC7_Check(
   input  clk,
   input  BITVAL,// Next input bit  
   input  Enable,                  
   input  rst,                           // Init CRC value  
   output reg [6:0] CRC                               // Current output CRC value
   );
   
     
    always @(posedge clk ) begin  
        if (rst) begin  
            CRC <= 7'b0;   
        end  
        else begin  
            if (Enable==1) begin  
                CRC[6] <= CRC[5];  
                CRC[5] <= CRC[4];  
                CRC[4] <= CRC[3];  
                CRC[3] <= CRC[2] ^ CRC[6];
                CRC[2] <= CRC[1];  
                CRC[1] <= CRC[0];  
                CRC[0] <= BITVAL ^ CRC[6]; 
            end  
            else 
            begin
              CRC<=CRC;
            end
        end  
     end  
     
endmodule
