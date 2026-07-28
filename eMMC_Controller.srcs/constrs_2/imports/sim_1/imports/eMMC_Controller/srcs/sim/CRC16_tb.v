`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/15 21:33:48
// Design Name: 
// Module Name: crc16_tb
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


module CRC16_tb;
    parameter ClockPeriod=10;  
    reg BITVAL,data,Enable,Enable_check,CLK,RST;  
    integer i=0;  
    wire [15:0]  CRC,CRC_check;  
      
    reg [23:0] cmd='h127ecb;    
    reg [23+16:0] cmd_encoded;  
    reg [7:0] error_bit=8'h00;
    initial begin  
    CLK=1'b1;  
    forever CLK =#(ClockPeriod /2) ~CLK;  
    end  
      
    initial begin  
    RST=1'b0;  
    Enable=1'b0; 
    Enable_check=1'b0;
    BITVAL=1'b0;
    data=1'b0;
    #10 RST=1;  
    #10 RST=0; 
    #100;
    #2;
     for(i=23;i>=0;i=i-1)  
     begin
       Enable=1'b1;
       BITVAL= cmd[i];
       #10;  
     end
     Enable=1'b0;
     #50;
    $display ("crc is %h",CRC);  
    #20 $stop();  
    
  
       // CRC7 Check 
       // if CRC== 0, then nothing wrong happens in the text.
       cmd_encoded=cmd;
       #20;
       cmd_encoded= (cmd_encoded<<16) ^ CRC;
       #20;
       cmd_encoded=cmd_encoded+error_bit;
       #100;
          for(i=23+16;i>=0;i=i-1)  
           begin
             Enable_check=1'b1;
             data= cmd_encoded[i];
             #10;  
          end 
          Enable_check=1'b0;  
           $display ("CRC_check is %h",CRC_check);  
           if(CRC_check==0)
           $display("CRC_check=0 indicates that the encoded data is transfered correctly.");
           else
            $display("CRC_check!=0 indicates that the encoded data is transfered errorously.");
          #20 $stop();     
  
    end  
    
     CRC16 crc16_inst( CLK, BITVAL, Enable, RST, CRC);
     CRC16_Check  crc16_check_inst(CLK,data, Enable_check,RST, CRC_check);       
   
endmodule
