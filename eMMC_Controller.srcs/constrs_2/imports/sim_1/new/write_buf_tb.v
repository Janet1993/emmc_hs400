`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/10/18 20:36:47
// Design Name: 
// Module Name: write_buf_tb
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


module write_buf_tb;
reg clka,rsta,ena,wea;
reg [7:0] addra;
reg [15:0] dina;
wire [15:0] douta;

integer i;

initial
begin
	clka = 0;
	rsta = 1;
	ena = 0;
	wea = 0;
	#10
	rsta = 0;
	#90
	ena = 1;
	wea =0;
	i = 0;
	#5000
	ena = 0;
end

always #5 clka = ~clka;

always@(posedge clka)
begin
	#100
	i <= i+1;
	addra <= i;
end
blk_mem_gen_0 inst1 (
  .clka(clka),    // input wire clka
  .rsta(rsta),    // input wire rsta
  .ena(ena),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [7 : 0] addra
  .dina(dina),    // input wire [15 : 0] dina
  .douta(douta)  // output wire [15 : 0] douta
);
endmodule
