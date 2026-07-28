`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/18 16:18:14
// Design Name: 
// Module Name: Test_eMMC_Controller
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


module Test_eMMC_Controller(
     input sysclk_100M,
     input sysrst,
     //
     output heartbeat,   
         //eMMC device interface
     output device_clk,           // clock for eMMC device
     output rst_n,                // Hardware reset for eMMC device
     input device_data_strobe,    // data strobe for data read in HS400 mode
     inout [7:0] device_data_bus, 
     inout device_cmd            // device command/response 
    
    );
  
  wire clk_200M;
  wire clk_200M_reverse;
  wire clk_200M_capture;
  wire clk_20M;
  wire data_fifo_full;
  reg [15:0] data_in;
  reg data_wr_en;
  reg cmd_wr_en;
  reg [63:0] cmd_in;
  wire cmd_fifo_full_w;
///////////////////////////////////////////////////
 
   clk_divided gen_clks
    (
    // Clock in ports
     .clk_in1(sysclk_100M),      // input clk_in1
     // Clock out ports
     .clk_200M(clk_200M),     // output clk_200M
	 .clk_200M_reverse(clk_200M_reverse),
	 .clk_200M_capture(clk_200M_capture),
	 .clk_20M(clk_20M),
     // Status and control signals
     .reset(sysrst), // input reset
     .locked()         // output locked
     );
 /////////////////////////////////////////////////////////////////////////////
 
///synchronization of system reset signal
  (* ASYNC_REG="true"*) reg [3:0]  synchronizer_ckt;
  wire synchronized_rst;
 always @ (posedge clk_200M or posedge sysrst)
 begin
    if(sysrst)
       synchronizer_ckt<=4'b1111;
    else
       synchronizer_ckt<={synchronizer_ckt[2:0], 1'b0};
 end
 assign synchronized_rst=synchronizer_ckt[3];
 ///////////////////////////////////////////////////////////
 
 // led bleaking to indicate whether the program has been loaded in to FPGA.
 reg [28:0] led_counter;
 always @( posedge clk_200M  )     begin
       led_counter <= led_counter + 1'b1;
   end
 assign heartbeat = led_counter[27]; 
     
   
     
 wire write_ready=~data_fifo_full;
 always @( posedge clk_200M  )     
 begin
        if(synchronized_rst) begin
           data_wr_en<=1'b0;
           data_in<=16'hffff;
        end
        else  if (write_ready) begin
            data_wr_en<=1'b1;
            data_in<=data_in-1'b1;
        end
        else begin
            data_wr_en<=1'b0;
            data_in<=data_in;
        end
 end
 /*
 wire cmd_write_ready=~cmd_fifo_full_w;
 always @( posedge clk_200M  )     
 begin
        if(synchronized_rst) begin
          cmd_wr_en<=1'b0;
          cmd_in[63:3]<='b1;
          cmd_in[2:0]<=3'b111;
          end
        else if(cmd_write_ready) begin
            cmd_wr_en<=1'b1 ;
            cmd_in[63]<=cmd_in[63]+1'b1;
            cmd_in[62:2]<=cmd_in[62:2]+1'b1;
        end
        else begin
           cmd_wr_en<=1'b0;
        end
 end 
 */
 reg [1:0] counter;
 
 wire cmd_write_ready=~cmd_fifo_full_w;
 always @( posedge clk_200M  )     
 begin
        if(synchronized_rst) begin
          cmd_wr_en<=1'b0;
          cmd_in[63:61]<=3'b100;
          cmd_in[60:0]<='d0;
          end
        else if(cmd_write_ready) begin
            cmd_wr_en<=1'b1 ;
            case(counter)
			0:begin
				cmd_in[63:61]<=3'b100;
				cmd_in[60:0]<='d0;
              end
			1:begin
				cmd_in[63:61]<=3'b000;
				cmd_in[60:0]<='d0;
			end
			2:begin
				cmd_in[63:61]<=3'b001;
				cmd_in[60:0]<='d0;
			end
			3:
			begin
				cmd_in[63:61]<=3'b001;
				cmd_in[60:0]<='d3;
			end
			default:begin
				cmd_in[63:61]<=3'b100;
				cmd_in[60:0]<='d0;
			end
			endcase
        end
        else begin
           cmd_wr_en<=1'b0;
        end
 end 
 
always @( posedge clk_200M  )     
 begin
        if(synchronized_rst) begin
          counter<=0;
          end
        else if(cmd_write_ready) begin
			counter<=counter+1;
        end
		else begin
           counter<=0;
        end
 end 
 

  eMMC_controller #(1) eMMC_controller_inst0(
         .clk_200M(clk_200M),                // input a 200M clock
         .clk_200M_reverse(clk_200M_reverse),
         .clk_200M_capture(clk_200M_capture),  
		 .clk_20M(clk_20M),
         .rst(synchronized_rst),                     // reset signal, active high
         
         // command write fifo interface
         .cmd_wr_en(cmd_wr_en),               //   commands input enable signal
         .cmd_in(cmd_in),           // 64-bit command input 
         .cmd_fifo_full(cmd_fifo_full_w),          // command fifo full flag
         
         //  write data input fifo
         .data_wr_en(data_wr_en),              //  write data enable signal
         .data_in(data_in),           // 16-bit data input, transfer 512Byte data( A block) one time from host 
         .data_fifo_full(data_fifo_full),         //fifo full flag
         
         // finished_command fifo interface
         .finished_cmd_rd_en(),      // finished commands read enable signal
         .finished_cmd_out(),// finished command to be read out 
         .finished_cmd_empty(),     // finished command fifo emputy flag
         
         // read data fifo interface
         .rd_data_rd_en(),          // read data fifo read enable signals
         .rd_data_out(),     // 16-bit data out, read 512Byte data( A block) out one time from read data fifo
         .rd_data_empty(),         // read data fifo empty flag
         
         //eMMC device interface
         .device_clk(device_clk),           // clock for eMMC device
         .rst_n(rst_n),                // Hardware reset for eMMC device
         .device_data_strobe(device_data_strobe),    // data strobe for data read in HS400 mode
         .device_data_bus(device_data_bus), 
         .device_cmd(device_cmd)           // device command/response 
         ); 
endmodule
