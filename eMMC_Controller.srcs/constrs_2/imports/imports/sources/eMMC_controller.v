`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: State Key Laboratory of High Performce Computing ( HPCL )
//          Natinal University of Denfense Technology
//          Changsha, China.
// Engineer: WU Lizhou
// 
// Create Date: 2016/08/17 19:41:20
// Design Name: A controller for Samsung eMMC device 
// Module Name: eMMC_controller
// Project Name: 
// Target Devices: KLMDG8JENB-B0s41 128 GB
// Tool Versions: Vivado 2015.4
// Description:  
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "Define.vh"
module eMMC_controller#(
    parameter DEVICE_NUMBER=1

)(
    input clk_200M,                // input a 200M clock
    input clk_200M_reverse,
	input clk_200M_capture,
	input clk_20M,
    input rst,                     // reset signal, active high
    
    // command write fifo interface
    input cmd_wr_en,               //   commands input enable signal
    input [63:0] cmd_in,           // 64-bit command input 
    output cmd_fifo_full,          // command fifo full flag
    
    //  write data input fifo
    input data_wr_en,              //  write data enable signal
    input [15:0] data_in,           // 8-bit data input, transfer 512Byte data( A block) one time from host 
    output data_fifo_full,         //fifo full flag
    
    // finished_command fifo interface
    input finished_cmd_rd_en,      // finished commands read enable signal
    output [63:0] finished_cmd_out,// finished command to be read out 
    output finished_cmd_empty,     // finished command fifo emputy flag
    
    // read data fifo interface
    input rd_data_rd_en,          // read data fifo read enable signals
    output [15:0] rd_data_out,     // 8-bit data out, read 512Byte data( A block) out one time from read data fifo
    output rd_data_empty,         // read data fifo empty flag
    
    //eMMC device interface
    output device_clk,           // clock for eMMC device
    output rst_n,                // Hardware reset for eMMC device
    input device_data_strobe,    // data strobe for data read in HS400 mode
    inout [7:0] device_data_bus, 
    inout device_cmd         // device command/response 
    );
    
 `include "log2.vh"
 `include "Parameter.vh"
 /// registers for simulation
 reg Test_device_cmd;   
 reg [7:0] Test_device_EXT_CSD;
 ///////////////////////////////////////////////////////////////////////////////////  
 // generation of clk_en signal of clock_A, which is 400K. T=512/200M=2560ns
 // clk_en is 1 clk_200M cycle high 
 reg clk_400K=1'b0;
 reg clk_400K_en=1'b0;
 reg [5:0] clk_counter='b0;
 always @( posedge  clk_20M)
 begin
  clk_counter<=clk_counter+1'b1;
   if(clk_counter==6'b10_0000)
         clk_400K_en<=1'b1;
     else 
         clk_400K_en<=1'b0;
 end
 always @( posedge  clk_20M)
 begin
    if(clk_counter[5]==1'b1)
       clk_400K<=1'b1;
    else
       clk_400K<=1'b0;
 end
 
 /////////////////////////////////////////////////////////////////////////////
 localparam DEVICE_DIMENSION=log2(DEVICE_NUMBER);

 reg HS400E_en;
 //
 wire device_response_in; // response from 3-state gate of device_cmd
  (* dont_touch = "true" *) wire [7:0] Device_data_bus_in;
 wire [7:0] Device_data_bus_out_DDR; // outputs data from ODDR registers to input pins of IOBUFs.
 reg [15:0] Device_data_bus_out;  // FPGA internal data feeding to the data ODDRs.
 reg Init_Transmission_dir; // Init_Transmission_dir =0 indicates that the default direction is from host to device
                            // Init_Transmission_dir =1 indicates that  transfer direction is from device to host
                           
 (* dont_touch = "true" *) reg [4:0] Curr_State, Next_State;
 reg start_transfer_cmd;
 reg start_receiving_resp;
 reg Start_check_resp;
 reg [39:0]device_cmd_tobe_sent;
 reg [7:0]Resp_length;
 (* dont_touch = "true" *) reg [DEVICE_DIMENSION:0] Device_selection_counter;
 //reg [127:0] Received_CID1,Received_CID2,Received_CID3,Received_CID4;
 reg [127:0] CID [DEVICE_NUMBER:1];
 reg [135:0] Received_resp_buff;
 wire [31:0] Device_status;
 wire [4:0] Error_CMD3,Error_CMD6,Error_CMD7;
 assign Device_status=Received_resp_buff[39:8];
 assign Error_CMD3={Device_status[25],Device_status[23],Device_status[22],Device_status[20],Device_status[19]};
 assign Error_CMD7=Error_CMD3;
 assign Error_CMD6=Error_CMD3;
 //
 (* dont_touch = "true" *)reg [135:0] HS400E_Received_resp_buff;
 wire [31:0] HS400E_Device_status=HS400E_Received_resp_buff[39:8];
 wire [4:0] HS400E_Error_CMD7={HS400E_Device_status[25],HS400E_Device_status[23],HS400E_Device_status[22],HS400E_Device_status[20],HS400E_Device_status[19]};
 wire [7:0] HS400E_Error_CMD24={HS400E_Device_status[31:29],HS400E_Device_status[25],HS400E_Device_status[23],HS400E_Device_status[22],HS400E_Device_status[20],HS400E_Device_status[19]};
// wire [4:0] HS400E_CRC_Status=HS400E_Received_resp_buff[4:0];
 ////////////////////////////////////////
 reg [5:0] Transfer_bit=6'b0;
 reg [39:0] device_cmd_temp_40='b0;
 //
 reg Cmd_transfer_end=1'b0;
 reg [5:0] Cmd_bit_counter=6'b0;
 
 reg Response_received=1'b0;
 reg [1:0] Check_resp_passed=2'b0;
 reg Response_Arriving;
 /////////////////////////////////////
//
reg [16:0] delay_counter;
wire Powerup_delay_end;
//
reg [4:0] Timer1=5'b0;
reg Timer1Start;
reg [6:0] Timer2='b0;
reg Timer2Start;
reg [10:0] HS400E_delay_counter;
reg HS400E_delay_counter_en;
//assign device_clk=clk_400K;
assign rst_n=~rst;
localparam UPPER_RCA=16-DEVICE_DIMENSION-1;
wire [39:0] CMD3={ {8'h43},{UPPER_RCA{1'b0}},Device_selection_counter,{16'b0}   }; //40 bits
wire [39:0] CMD7_4ACTIVATION={ {8'h47},{UPPER_RCA{1'b0}},Device_selection_counter,{16'b0} };

wire [7:0] Device_data_bus_idealy;
/***********************Select the logic block to output*****************************************************************************************/
// If HS400 Enhanced Strobe mode is activated under the backwards compatibility mode, HS400_en is asserted.
// After activation of HS400E, this controller shall enable the HS400E controlling logic block, which is expected to interface with the devices.
(* IOB="TRUE" *) (* dont_touch = "true" *) reg [8:0] Transmission_dir;
reg HS400E_Transmission_dir;  //0: output  1: input
reg Init_Device_cmd_out; // output commmand to inout device_cmd

(* IOB="TRUE" *)reg Device_cmd_out;
reg HS400E_Device_cmd_out;

 always @( posedge  clk_200M)
 begin
	if(HS400E_en) begin
	  Transmission_dir<={9{HS400E_Transmission_dir}};
	  
	  Device_cmd_out<=HS400E_Device_cmd_out;
	end
	else begin
      Transmission_dir<= {9{Init_Transmission_dir}};
	  Device_cmd_out<=Init_Device_cmd_out;
	end
 end
/********************************END*************************************************************************************************************/
/****************************Explicit Instantiation of IOBUFs for inout pins of eMMC devices*****************************************************/
// IOBUF: Single-ended Bi-directional Buffer
// All devices
// Xilinx HDL Libraries Guide, version 14.7

//Device CMD signal 
IOBUF #(
.DRIVE(12), // Specify the output drive strength
.IBUF_LOW_PWR("FALSE"), // Low Power - "TRUE", High Performance = "FALSE"
.IOSTANDARD("LVCMOS18"), // Specify the I/O standard
.SLEW("FAST") // Specify the output slew rate
) IOBUF_device_cmd(
.O(device_response_in), // Buffer output
.IO(device_cmd), // Buffer inout port (connect directly to top-level port)
.I(Device_cmd_out), // Buffer input
.T(Transmission_dir[8]) // 3-state enable input, high=input, low=output
);

// data bus 

IOBUF #(
.DRIVE(12), // Specify the output drive strength
.IBUF_LOW_PWR("FALSE"), // Low Power - "TRUE", High Performance = "FALSE"
.IOSTANDARD("LVCMOS18"), // Specify the I/O standard
.SLEW("FAST") // Specify the output slew rate
) IOBUF_device_data_bus7(
.O (Device_data_bus_in[7]), // Buffer output
.IO   (device_data_bus[7]), // Buffer inout port (connect directly to top-level port)
.I(Device_data_bus_out_DDR[7]), // Buffer input
.T(Transmission_dir[7]) // 3-state enable input, high=input, low=output
);
IOBUF #(
.DRIVE(12), // Specify the output drive strength
.IBUF_LOW_PWR("FALSE"), // Low Power - "TRUE", High Performance = "FALSE"
.IOSTANDARD("LVCMOS18"), // Specify the I/O standard
.SLEW("FAST") // Specify the output slew rate
) IOBUF_device_data_bus6(
.O (Device_data_bus_in[6]), // Buffer output
.IO   (device_data_bus[6]), // Buffer inout port (connect directly to top-level port)
.I(Device_data_bus_out_DDR[6]), // Buffer input
.T(Transmission_dir[6]) // 3-state enable input, high=input, low=output
);
IOBUF #(
.DRIVE(12), // Specify the output drive strength
.IBUF_LOW_PWR("FALSE"), // Low Power - "TRUE", High Performance = "FALSE"
.IOSTANDARD("LVCMOS18"), // Specify the I/O standard
.SLEW("FAST") // Specify the output slew rate
) IOBUF_device_data_bus5(
.O (Device_data_bus_in[5]), // Buffer output
.IO   (device_data_bus[5]), // Buffer inout port (connect directly to top-level port)
.I(Device_data_bus_out_DDR[5]), // Buffer input
.T(Transmission_dir[5]) // 3-state enable input, high=input, low=output
);
IOBUF #(
.DRIVE(12), // Specify the output drive strength
.IBUF_LOW_PWR("FALSE"), // Low Power - "TRUE", High Performance = "FALSE"
.IOSTANDARD("LVCMOS18"), // Specify the I/O standard
.SLEW("FAST") // Specify the output slew rate
) IOBUF_device_data_bus4(
.O (Device_data_bus_in[4]), // Buffer output
.IO   (device_data_bus[4]), // Buffer inout port (connect directly to top-level port)
.I(Device_data_bus_out_DDR[4]), // Buffer input
.T(Transmission_dir[4]) // 3-state enable input, high=input, low=output
);
IOBUF #(
.DRIVE(12), // Specify the output drive strength
.IBUF_LOW_PWR("FALSE"), // Low Power - "TRUE", High Performance = "FALSE"
.IOSTANDARD("LVCMOS18"), // Specify the I/O standard
.SLEW("FAST") // Specify the output slew rate
) IOBUF_device_data_bus3(
.O (Device_data_bus_in[3]), // Buffer output
.IO   (device_data_bus[3]), // Buffer inout port (connect directly to top-level port)
.I(Device_data_bus_out_DDR[3]), // Buffer input
.T(Transmission_dir[3]) // 3-state enable input, high=input, low=output
);
IOBUF #(
.DRIVE(12), // Specify the output drive strength
.IBUF_LOW_PWR("FALSE"), // Low Power - "TRUE", High Performance = "FALSE"
.IOSTANDARD("LVCMOS18"), // Specify the I/O standard
.SLEW("FAST") // Specify the output slew rate
) IOBUF_device_data_bus2(
.O (Device_data_bus_in[2]), // Buffer output
.IO   (device_data_bus[2]), // Buffer inout port (connect directly to top-level port)
.I(Device_data_bus_out_DDR[2]), // Buffer input
.T(Transmission_dir[2]) // 3-state enable input, high=input, low=output
);
IOBUF #(
.DRIVE(12), // Specify the output drive strength
.IBUF_LOW_PWR("FALSE"), // Low Power - "TRUE", High Performance = "FALSE"
.IOSTANDARD("LVCMOS18"), // Specify the I/O standard
.SLEW("FAST") // Specify the output slew rate
) IOBUF_device_data_bus1(
.O (Device_data_bus_in[1]), // Buffer output
.IO   (device_data_bus[1]), // Buffer inout port (connect directly to top-level port)
.I(Device_data_bus_out_DDR[1]), // Buffer input
.T(Transmission_dir[1]) // 3-state enable input, high=input, low=output
);
IOBUF #(
.DRIVE(12), // Specify the output drive strength
.IBUF_LOW_PWR("FALSE"), // Low Power - "TRUE", High Performance = "FALSE"
.IOSTANDARD("LVCMOS18"), // Specify the I/O standard
.SLEW("FAST") // Specify the output slew rate
) IOBUF_device_data_bus0(
.O (Device_data_bus_in[0]), // Buffer output
.IO   (device_data_bus[0]), // Buffer inout port (connect directly to top-level port)
.I(Device_data_bus_out_DDR[0]), // Buffer input
.T(Transmission_dir[0]) // 3-state enable input, high=input, low=output
);

/***************Instantiate the IDELAYCTRL primitive ***********/

 
	(* IODELAY_GROUP = "iodelay_delayDQS" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
	IDELAYCTRL IDELAYCTRL_inst (
	.RDY(), // 1-bit Indicates the validity of the reference clock input, REFCLK. When REFCLK
	// disappears (i.e., REFCLK is held High or Low for one clock period or more), the RDY
	// signal is deasserted.
	.REFCLK(clk_200M), // 1-bit Provides a voltage bias, independent of process, voltage, and temperature
	// variations, to the tap-delay lines in the IOBs. The frequency of REFCLK must be 200
	// MHz to guarantee the tap-delay value specified in the applicable data sheet.
	.RST(rst) // 1-bit Resets the IDELAYCTRL circuitry. The RST signal is an active-high asynchronous
	// reset. To reset the IDELAYCTRL, assert it High for at least 50 ns.
	);
// End of IDELAYCTRL_inst instantiation



/*************Instantiate the IODELAYE1 primitive**************/
reg tap_change_en;
reg tap_change_init;

	(* IODELAY_GROUP = "iodelay_delayDQS" *) // Specifies group name for associated IODELAYs and IDELAYCTRL
	IDELAYE2 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("IDATAIN"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("VARIABLE"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(0), // Input delay tap setting (0-32) 
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IDELAYE2_inst_7 (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(Device_data_bus_idealy[7]), // 1-bit output - Delayed data output
	.C(clk_200M), // 1-bit input - Clock input
	.CE(tap_change_en), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(Device_data_bus_in[7]), // 1-bit input - Delay data input
	.INC(1'b1), // 1-bit input - Increment / Decrement tap delay
	.LD(tap_change_init),
	.LDPIPEEN(),
	.REGRST() // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	);
	
	(* IODELAY_GROUP = "iodelay_delayDQS" *) 
	IDELAYE2 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("IDATAIN"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("VARIABLE"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(0), // Input delay tap setting (0-32) 
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IDELAYE2_inst_6 (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(Device_data_bus_idealy[6]), // 1-bit output - Delayed data output
	.C(clk_200M), // 1-bit input - Clock input
	.CE(tap_change_en), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(Device_data_bus_in[6]), // 1-bit input - Delay data input
	.INC(1'b1), // 1-bit input - Increment / Decrement tap delay
	.LD(tap_change_init),
	.LDPIPEEN(),
	.REGRST() // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	);
	
	(* IODELAY_GROUP = "iodelay_delayDQS" *) 
	IDELAYE2 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("IDATAIN"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("VARIABLE"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(0), // Input delay tap setting (0-32) 
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IDELAYE2_inst_5 (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(Device_data_bus_idealy[5]), // 1-bit output - Delayed data output
	.C(clk_200M), // 1-bit input - Clock input
	.CE(tap_change_en), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(Device_data_bus_in[5]), // 1-bit input - Delay data input
	.INC(1'b1), // 1-bit input - Increment / Decrement tap delay
	.LD(tap_change_init),
	.LDPIPEEN(),
	.REGRST() // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	 );
	 
	(* IODELAY_GROUP = "iodelay_delayDQS" *) 
	IDELAYE2 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("IDATAIN"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("VARIABLE"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(0), // Input delay tap setting (0-32) 
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IDELAYE2_inst_4 (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(Device_data_bus_idealy[4]), // 1-bit output - Delayed data output
	.C(clk_200M), // 1-bit input - Clock input
	.CE(tap_change_en), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(Device_data_bus_in[4]), // 1-bit input - Delay data input
	.INC(1'b1), // 1-bit input - Increment / Decrement tap delay
	.LD(tap_change_init),
	.LDPIPEEN(),
	.REGRST() // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	);
	
	(* IODELAY_GROUP = "iodelay_delayDQS" *) 
	IDELAYE2 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("IDATAIN"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("VARIABLE"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(0), // Input delay tap setting (0-32) 
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IDELAYE2_inst_3 (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(Device_data_bus_idealy[3]), // 1-bit output - Delayed data output
	.C(clk_200M), // 1-bit input - Clock input
	.CE(tap_change_en), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(Device_data_bus_in[3]), // 1-bit input - Delay data input
	.INC(1'b1), // 1-bit input - Increment / Decrement tap delay
	.LD(tap_change_init),
	.LDPIPEEN(),
	.REGRST() // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	);
	
	(* IODELAY_GROUP = "iodelay_delayDQS" *) 
	IDELAYE2 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("IDATAIN"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("VARIABLE"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(0), // Input delay tap setting (0-32) 
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IDELAYE2_inst_2 (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(Device_data_bus_idealy[2]), // 1-bit output - Delayed data output
	.C(clk_200M), // 1-bit input - Clock input
	.CE(tap_change_en), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(Device_data_bus_in[2]), // 1-bit input - Delay data input
	.INC(1'b1), // 1-bit input - Increment / Decrement tap delay
	.LD(tap_change_init),
	.LDPIPEEN(),
	.REGRST() // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	);
	
	(* IODELAY_GROUP = "iodelay_delayDQS" *) 
	IDELAYE2 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("IDATAIN"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("VARIABLE"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(0), // Input delay tap setting (0-32) 
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IDELAYE2_inst_1 (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(Device_data_bus_idealy[1]), // 1-bit output - Delayed data output
	.C(clk_200M), // 1-bit input - Clock input
	.CE(tap_change_en), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(Device_data_bus_in[1]), // 1-bit input - Delay data input
	.INC(1'b1), // 1-bit input - Increment / Decrement tap delay
	.LD(tap_change_init),
	.LDPIPEEN(),
	.REGRST() // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	);
	
	(* IODELAY_GROUP = "iodelay_delayDQS" *) 
	IDELAYE2 #(
	.CINVCTRL_SEL("FALSE"), // Enable dynamic clock inversion ("TRUE"/"FALSE")
	.DELAY_SRC("IDATAIN"), // Delay input ("I", "CLKIN", "DATAIN", "IO", "O")
	.HIGH_PERFORMANCE_MODE("TRUE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
	.IDELAY_TYPE("VARIABLE"), // "DEFAULT", "FIXED", "VARIABLE", or "VAR_LOADABLE"
	.IDELAY_VALUE(0), // Input delay tap setting (0-32) 
	.REFCLK_FREQUENCY(200), // IDELAYCTRL clock input frequency in MHz
	.SIGNAL_PATTERN("DATA") // "DATA" or "CLOCK" input signal
	)
	IDELAYE2_inst_0 (
	.CNTVALUEOUT(), // 5-bit output - Counter value for monitoring purpose
	.DATAOUT(Device_data_bus_idealy[0]), // 1-bit output - Delayed data output
	.C(clk_200M), // 1-bit input - Clock input
	.CE(tap_change_en), // 1-bit input - Active high enable increment/decrement function
	.CINVCTRL(), // 1-bit input - Dynamically inverts the Clock (C) polarity
	.CNTVALUEIN(), // 5-bit input - Counter value for loadable counter application
	.DATAIN(), // 1-bit input - Internal delay data
	.IDATAIN(Device_data_bus_in[0]), // 1-bit input - Delay data input
	.INC(1'b1), // 1-bit input - Increment / Decrement tap delay
	.LD(tap_change_init),
	.LDPIPEEN(),
	.REGRST() // 1-bit input - Active high, synchronous reset, resets delay chain to IDELAY_VALUE/
	);
// End of IODELAYE1_inst instantiation
////////
// End of IOBUF_inst instantiation

   // BUFGMUX_CTRL: 2-to-1 Global Clock MUX Buffer
   //               Virtex-7
   // Xilinx HDL Language Template, version 2015.4
   
 wire Device_clk_control;
   BUFGMUX_CTRL BUFGMUX_CTRL_inst (
      .O(Device_clk_control),   // 1-bit output: Clock output
      .I0(clk_400K), // 1-bit input: Clock input (S=0)
      .I1(clk_200M_reverse), // 1-bit input: Clock input (S=1)
      .S(HS400E_en)    // 1-bit input: Clock select
   );
   // End of BUFGMUX_CTRL_inst instantiation
 //Instantiation of IDDRs
 
 (* dont_touch = "true" *) wire [7:0] Device_data_bus_in_p;
 (* dont_touch = "true" *) wire [7:0] Device_data_bus_in_n;
  IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                      //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b1), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b1), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) IDDR_data_in_0 (
      .Q1(Device_data_bus_in_p[0]), // 1-bit output for positive edge of clock 
      .Q2(Device_data_bus_in_n[0]), // 1-bit output for negative edge of clock
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(Device_data_bus_idealy[0]),   // 1-bit DDR data input
	  //.D(Test_device_cmd),   // 1-bit DDR data input[0]),   // 1-bit DDR data input
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   ); 
   IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                      //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b1), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b1), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) IDDR_data_in_1 (
      .Q1(Device_data_bus_in_p[1]), // 1-bit output for positive edge of clock 
      .Q2(Device_data_bus_in_n[1]), // 1-bit output for negative edge of clock
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(Device_data_bus_idealy[1]),   // 1-bit DDR data input
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   ); 
      IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                      //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b1), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b1), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) IDDR_data_in_2 (
      .Q1(Device_data_bus_in_p[2]), // 1-bit output for positive edge of clock 
      .Q2(Device_data_bus_in_n[2]), // 1-bit output for negative edge of clock
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(Device_data_bus_idealy[2]),   // 1-bit DDR data input
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   ); 
         IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                      //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b1), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b1), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) IDDR_data_in_3 (
      .Q1(Device_data_bus_in_p[3]), // 1-bit output for positive edge of clock 
      .Q2(Device_data_bus_in_n[3]), // 1-bit output for negative edge of clock
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(Device_data_bus_idealy[3]),   // 1-bit DDR data input
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );
         IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                      //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b1), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b1), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) IDDR_data_in_4(
      .Q1(Device_data_bus_in_p[4]), // 1-bit output for positive edge of clock 
      .Q2(Device_data_bus_in_n[4]), // 1-bit output for negative edge of clock
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(Device_data_bus_idealy[4]),   // 1-bit DDR data input
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );
         IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                      //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b1), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b1), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) IDDR_data_in_5 (
      .Q1(Device_data_bus_in_p[5]), // 1-bit output for positive edge of clock 
      .Q2(Device_data_bus_in_n[5]), // 1-bit output for negative edge of clock
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(Device_data_bus_idealy[5]),   // 1-bit DDR data input
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );
         IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                      //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b1), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b1), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) IDDR_data_in_6 (
      .Q1(Device_data_bus_in_p[6]), // 1-bit output for positive edge of clock 
      .Q2(Device_data_bus_in_n[6]), // 1-bit output for negative edge of clock
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(Device_data_bus_idealy[6]),   // 1-bit DDR data input
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );
         IDDR #(
      .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                      //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b1), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b1), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) IDDR_data_in_7 (
      .Q1(Device_data_bus_in_p[7]), // 1-bit output for positive edge of clock 
      .Q2(Device_data_bus_in_n[7]), // 1-bit output for negative edge of clock
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(Device_data_bus_idealy[7]),   // 1-bit DDR data input
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );
   
  //Instantiation of ODDRs  
     ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_fwd_clk (
      .Q(device_clk),   // 1-bit DDR output
      .C(Device_clk_control),   // 1-bit clock input
      .CE(1), // 1-bit clock enable input
      .D1(1'b1), // 1-bit data input (positive edge)
      .D2(1'b0), // 1-bit data input (negative edge)
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );
   
      ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_data_out_0 (
      .Q( Device_data_bus_out_DDR[0]),   // 1-bit DDR output
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(Device_data_bus_out[8]), // 1-bit data input (positive edge)
      .D2(Device_data_bus_out[0]), // 1-bit data input (negative edge)
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );  
       ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_data_out_1 (
      .Q(Device_data_bus_out_DDR[1]),   // 1-bit DDR output
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(Device_data_bus_out[9]), // 1-bit data input (positive edge)
      .D2(Device_data_bus_out[1]), // 1-bit data input (negative edge)
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   ); 
      ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_data_out_2 (
      .Q(Device_data_bus_out_DDR[2]),   // 1-bit DDR output
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(Device_data_bus_out[10]), // 1-bit data input (positive edge)
      .D2(Device_data_bus_out[2]), // 1-bit data input (negative edge)
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );     
      ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_data_out_3 (
      .Q(Device_data_bus_out_DDR[3]),   // 1-bit DDR output
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(Device_data_bus_out[11]), // 1-bit data input (positive edge)
      .D2(Device_data_bus_out[3]), // 1-bit data input (negative edge)
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );   
      ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_data_out_4 (
      .Q(Device_data_bus_out_DDR[4]),   // 1-bit DDR output
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(Device_data_bus_out[12]), // 1-bit data input (positive edge)
      .D2(Device_data_bus_out[4]), // 1-bit data input (negative edge)
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );    
      ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_data_out_5 (
      .Q(Device_data_bus_out_DDR[5]),   // 1-bit DDR output
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(Device_data_bus_out[13]), // 1-bit data input (positive edge)
      .D2(Device_data_bus_out[5]), // 1-bit data input (negative edge)
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );  
      ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_data_out_6 (
      .Q(Device_data_bus_out_DDR[6]),   // 1-bit DDR output
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(Device_data_bus_out[14]), // 1-bit data input (positive edge)
      .D2(Device_data_bus_out[6]), // 1-bit data input (negative edge)
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   ); 
      ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_data_out_7 (
      .Q(Device_data_bus_out_DDR[7]),   // 1-bit DDR output
      .C(clk_200M),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(Device_data_bus_out[15]), // 1-bit data input (positive edge)
      .D2(Device_data_bus_out[7]), // 1-bit data input (negative edge)
      .R(),   // 1-bit reset
      .S()    // 1-bit set
   );    
   wire Device_Ready=Device_data_bus_idealy[0]; // 0: busy, 1: ready.
/**************************************END ************************END *************************************************************************/
/******************************The main state machine for HS400 Enhanced Strobe Operations******************************************************/
//Command format:
//-------------------------------------------------------------------------------------
//| 63-61 | 60-53    | 52-34        | 33-31            | 30-3           |  2-0             |
//|  op   | reserved | Dram address | channel address  | sector address | sector offset    |
//-------------------------------------------------------------------------------------
 wire  Is_cmd_fifo_empty;
 reg rd_cmd_en;
 wire [63:0] rd_cmd_out_w;
 reg [63:0] rd_cmd_temp; 
  Command_fifo Command_fifo_inst0 (
      .clk(clk_200M),      // input wire clk
      .srst(rst),    // input wire srst
      .din(cmd_in),      // input wire [63 : 0] din
      .wr_en(cmd_wr_en),  // input wire wr_en
      .rd_en(rd_cmd_en),  // input wire rd_en
      .dout(rd_cmd_out_w),    // output wire [63 : 0] dout
      .full(cmd_fifo_full),    // output wire full
      .empty(Is_cmd_fifo_empty)  // output wire empty
    );
	
 (* dont_touch = "true" *) reg [4:0] HS400E_Curr_State, HS400E_Next_State;
 reg HS400E_start_write;
 (* dont_touch = "true" *)reg HS400E_write_end;
 reg HS400E_start_read;
 reg HS400E_read_end;
 wire [2:0] Operation_type=rd_cmd_temp[63:61]; // 1: write 0:read
 wire [DEVICE_DIMENSION:0] Channel_addr=rd_cmd_temp[31+DEVICE_DIMENSION:31]; //channel address 
 wire [27:0] Sector_addr=rd_cmd_temp[30:3];
 wire [2:0] Sector_offset=rd_cmd_temp[2:0];
 reg [DEVICE_DIMENSION:0] Device_addr;
 
 wire [39:0] HS400E_CMD7={ {8'h47}, Sector_addr };
 wire [39:0] HS400E_CMD24={  {8'h58}, 4'b0, Sector_addr };
 wire [39:0] HS400E_CMD17={  {8'h51}, 4'b0,  Sector_addr };
 
 wire [39:0] HS400E_CMD_tuning_w={  {8'h58}, 4'b0, 28'd0 };
 wire [39:0] HS400E_CMD_tuning_r={  {8'h51}, 4'b0,  28'd0 };
 reg write_end_rece;
 reg Finished_tuning;
 reg Finished_cmd_wr_en;
 wire Finished_cmd_fifo_full;
 reg turning_end_rst;
 
 wire rd_buf_wr_en;
wire fifo_wr_en;
assign rd_buf_wr_en = (Data_Arriving==1'b1)&&(Data_bit_counter<=255);
(* dont_touch = "true" *) reg [15:0] rd_data_final;

assign fifo_wr_en = (Fifo_bit_counter<'d258)&&(Fifo_bit_counter>'d1);	
wire rd_data_fifo_en;
assign rd_data_fifo_en = Steps_rd_data_fifo_en&&(!write_data_again_en);
 
always@(posedge clk_200M)
begin
  if(rst)
  		HS400E_Curr_State<=H_Waiting4_HS400E;
  else 
        HS400E_Curr_State<=HS400E_Next_State;  
end 

always@(*)
begin
   HS400E_Next_State=H_Waiting4_HS400E;
	case(HS400E_Curr_State)
		H_Waiting4_HS400E:begin
	       if(HS400E_en==1'b1)
		      HS400E_Next_State=H_Delay_100us_4Clk_up;
		   else 
		       HS400E_Next_State=H_Waiting4_HS400E;
		end
		H_Delay_100us_4Clk_up:begin
		   if(HS400E_delay_counter[10]==1'b1)
		      HS400E_Next_State=H_Idel;
		   else
		     HS400E_Next_State=H_Delay_100us_4Clk_up;
		end
		
		//Fetch and extract commands from command write fifo
		H_Idel:begin
			if(Finished_tuning)
			begin
				if(Is_cmd_fifo_empty==1'b0)
					HS400E_Next_State=H_Fetch_cmd;
				else 
					HS400E_Next_State=H_Idel;	
		    end
			else
			begin
				HS400E_Next_State=H_Tuning_start;
			end
		end
		H_Tuning_start:begin
			HS400E_Next_State=H_Writing_data_512B;
		end
		H_Tuning_end:begin
			HS400E_Next_State=H_Idel;
		end
		H_Fetch_cmd:begin
			HS400E_Next_State=H_Extract_cmd;
		end
		H_Extract_cmd:begin
		   if(Operation_type[2]==1'b1) //write
				HS400E_Next_State=H_Writing_data_512B;
				//HS400E_Next_State=H_Write_finished_cmd;
		   else//read 
		       HS400E_Next_State=H_Reading_data_512B;
		end
	    H_Writing_data_512B:begin
		    if(HS400E_write_end)
			begin
				if(Finished_tuning)
					HS400E_Next_State=H_Is_finished_cmd_fifo_full;
				else
					HS400E_Next_State=H_Reading_data_512B;
			end
			else
			begin
			   HS400E_Next_State=H_Writing_data_512B;
			end
		end
		H_Reading_data_512B:begin
			if(HS400E_read_end)
			begin
				if(Finished_tuning)
					HS400E_Next_State=H_Is_finished_cmd_fifo_full;
				else
					HS400E_Next_State=H_Tuning_end; 
			end
			else
			begin
			   HS400E_Next_State=H_Reading_data_512B;
			end
		end
		H_Is_finished_cmd_fifo_full:begin
		  if(Finished_cmd_fifo_full)
		     HS400E_Next_State=H_Is_finished_cmd_fifo_full;
		  else 
		     HS400E_Next_State=H_finished_cmd;
		end 
		H_finished_cmd:begin
		  HS400E_Next_State=H_Idel;
		end
		default: begin
		   HS400E_Next_State=H_Waiting4_HS400E;
		end

	endcase
end


always@(posedge clk_200M)
begin	
	case(HS400E_Next_State)
		H_Waiting4_HS400E:begin
	
			HS400E_start_write<=1'b0;
			HS400E_start_read<=1'b0;
			HS400E_delay_counter_en<=1'b0;
		    rd_cmd_en<=1'b0;
			rd_cmd_temp<=64'b0;
			Finished_cmd_wr_en<=1'b0;
			Finished_tuning<=1'b0;
			turning_end_rst<=1'b0;
			write_end_rece<=1'b0;
		end  
		H_Delay_100us_4Clk_up:begin
         
			HS400E_start_write<=1'b0;
			HS400E_start_read<=1'b0;
		    HS400E_delay_counter_en<=1'b1;
		    rd_cmd_en<=1'b0;
			rd_cmd_temp<=64'b0;		
			Finished_cmd_wr_en<=1'b0;	
			Finished_tuning<=1'b0;
			turning_end_rst<=1'b0;
			write_end_rece<=1'b0;			
		end
		H_Idel:begin
       
			HS400E_start_write<=1'b0;
			HS400E_start_read<=1'b0;
		    HS400E_delay_counter_en<=1'b0;	
		    rd_cmd_en<=1'b0;
			rd_cmd_temp<=rd_cmd_out_w;
			Finished_cmd_wr_en<=1'b0;	
			Finished_tuning<=Finished_tuning;
			turning_end_rst<=1'b0;
			write_end_rece<=1'b0;
		end
		H_Tuning_start:begin
			HS400E_start_write<=1'b0;
			HS400E_start_read<=1'b0;
			rd_cmd_en<=1'b0;
			Finished_cmd_wr_en<=1'b0;
			HS400E_delay_counter_en<=1'b0;	
			Finished_tuning<=1'b0;	
			rd_cmd_temp<=64'b0;
			turning_end_rst<=1'b0;
			write_end_rece<=1'b0;
		end
		H_Tuning_end:begin
			HS400E_start_write<=1'b0;
			HS400E_start_read<=1'b0;
			rd_cmd_en<=1'b0;
			Finished_cmd_wr_en<=1'b0;
			HS400E_delay_counter_en<=1'b0;	
			Finished_tuning<=1'b1;
			rd_cmd_temp<=64'b0;
			turning_end_rst<=1'b1;
			write_end_rece<=1'b0;
		end
		H_Fetch_cmd:begin//03
		    rd_cmd_en<=1'b1;	
			rd_cmd_temp<=rd_cmd_out_w;	
			Finished_cmd_wr_en<=1'b1;	
			Finished_tuning<=1'b1;
			turning_end_rst<=1'b0;	
			write_end_rece<=1'b0;			
		end
		H_Extract_cmd:begin//04
		    rd_cmd_en<=1'b0;
			Device_addr<=Channel_addr+1'b1;
			Finished_cmd_wr_en<=1'b1;	
			Finished_tuning<=1'b1;
			turning_end_rst<=1'b0;
			write_end_rece<=1'b0;
		end
	    H_Writing_data_512B:begin//05
		
			HS400E_start_write<=1'b1;
			HS400E_start_read<=1'b0;
			HS400E_delay_counter_en<=1'b0;
			rd_cmd_en<=1'b0;
			Finished_cmd_wr_en<=1'b0;	
			Finished_tuning<=Finished_tuning;
			turning_end_rst<=1'b0;
			write_end_rece<=1'b0;	
		end	
		H_Reading_data_512B:begin//06
		   HS400E_start_write<=1'b0;
		   HS400E_start_read<=1'b1;
		   Finished_cmd_wr_en<=1'b0;
		   rd_cmd_en<=1'b0;
		   Finished_cmd_wr_en<=1'b0;
		   Finished_tuning<=Finished_tuning;
		   turning_end_rst<=1'b0;
		   write_end_rece<=1'b1;
		end	
		H_Is_finished_cmd_fifo_full:begin
		  Finished_cmd_wr_en<=1'b0;
		  HS400E_start_write<=1'b0;
		  HS400E_start_read<=1'b0;
		  rd_cmd_en<=1'b0;
		  HS400E_delay_counter_en<=1'b0;
		  Finished_tuning<=1'b1;
		  turning_end_rst<=1'b0;
		  write_end_rece<=1'b1;
		end 
		H_finished_cmd:begin
		  Finished_cmd_wr_en<=1'b1;
		  HS400E_start_write<=1'b0;
		  HS400E_start_read<=1'b0;
		  rd_cmd_en<=1'b0;
		  HS400E_delay_counter_en<=1'b0;
		  Finished_tuning<=1'b1;
		  turning_end_rst<=1'b0;
		  write_end_rece<=1'b1;
		end 
		default: begin
		
		end
	endcase
end
/******************************END**********************************************END**************************************************************/
/******************************The main state machine for detailed steps of an operation under HS400 Enhanced Strobe mode.(200M clock) **********/
 (* dont_touch = "true" *) reg [4:0] Steps_Curr_State, Steps_Next_State;
reg HS400E_start_transfer_cmd;
reg HS400E_Cmd_transfer_end;
reg [39:0]HS400E_device_cmd_tobe_sent;
(* dont_touch = "true" *)reg [7:0] HS400E_Resp_length;
reg HS400E_start_receiving_resp;
reg  HS400E_Response_received;

reg Steps_start_receiving_data;
reg Data_Arriving;
reg Data_received;
reg Steps_start_sending_data;
reg Steps_sending_data_end;
reg HS400E_start_receiving_crc_status;
reg HS400E_crc16_status_end;
reg [3:0] HS400E_Received_crc16_status;

reg write_buf_en;
reg data_source_select; //0:fifo 1:buffer
 reg crc16_check_rst;
 reg write_data_again_en;//0:write normal 1:write data from buffer
 reg fifo_wr_end;
reg fifo_wr_start;

(* dont_touch = "true" *)wire crc16_check_result;
assign crc16_check_result= crc16_check_and0 | crc16_check_and1 | crc16_check_and2 | crc16_check_and3;
always@(posedge clk_200M)
begin
  if(rst)
  		Steps_Curr_State<=Steps_delay_16cc;
  else 
        Steps_Curr_State<=Steps_Next_State;  
end 

always@(*)
begin
   Steps_Next_State=Steps_delay_16cc;
	case(Steps_Curr_State)
		Steps_delay_16cc:begin
            if (Timer2==7'b100_0000 )
              Steps_Next_State=Steps_idle;
			//  Steps_Next_State=Steps_sending_CMD7;
			//   Steps_Next_State=Steps_sending_CMD8;
			else
			  Steps_Next_State=Steps_delay_16cc;
        end	
		
		Steps_idle:begin
			if(Finished_tuning)
			begin
				if(HS400E_start_write)
					Steps_Next_State=Steps_sending_CMD24;
				else if(HS400E_start_read)
					Steps_Next_State=Steps_sending_CMD17;
				else 
					Steps_Next_State=Steps_idle;
			end
			else
			begin
				if(HS400E_start_write)
					Steps_Next_State= Steps_tuning_cmd_w;
				else if(HS400E_start_read)
					Steps_Next_State=Steps_tuning_cmd_r;
				else 
					Steps_Next_State=Steps_idle;
			end
           
		end
		/*
		Steps_sending_CMD8:begin
		   if(HS400E_Cmd_transfer_end)
		      Steps_Next_State=Steps_receiving_EXT_CSD;
		   else
		      Steps_Next_State=Steps_sending_CMD8;
		end
        Steps_receiving_EXT_CSD:begin
            if(Data_received)
			   Steps_Next_State=Steps_halt;
			else
			   Steps_Next_State= Steps_receiving_EXT_CSD; 
		end
		
		Steps_halt:begin
		    Steps_Next_State=Steps_halt;
		
		end
		
		
		Steps_sending_CMD7:begin
   	      if(HS400E_Cmd_transfer_end)
		     Steps_Next_State=Steps_receiving_resp_4CMD7;
	      else 
		      Steps_Next_State=Steps_sending_CMD7;         
        end		
		Steps_receiving_resp_4CMD7 :begin
		    if(Timer2==7'b100_0000 )
		        Steps_Next_State=Steps_sending_CMD24;
		   else if(HS400E_Response_received)
			 Steps_Next_State=Steps_check_resp_4CMD7;
		   else
            Steps_Next_State=Steps_receiving_resp_4CMD7;
		end
		Steps_check_resp_4CMD7:begin
		   if(HS400E_Error_CMD7=='b0)
		      if(Timer2==7'b100_0000)
		        Steps_Next_State=Steps_sending_CMD24;
			  else
			   Steps_Next_State=Steps_check_resp_4CMD7;
		   else
		     if(Timer2==7'b100_0000)
		        Steps_Next_State=Steps_sending_CMD7;
			  else
			   Steps_Next_State=Steps_check_resp_4CMD7;
		end
		*/
		Steps_sending_CMD24:begin
    	      if(HS400E_Cmd_transfer_end)
    	      `ifdef SIMULATION
    	          Steps_Next_State=Steps_sendingdata_512B;
    	      `else
		          Steps_Next_State=Steps_receiving_resp_4CMD24;
		      `endif
	      else 
		      Steps_Next_State=Steps_sending_CMD24;          
        end   
        Steps_tuning_cmd_w:begin
			if(HS400E_Cmd_transfer_end)
    	      `ifdef SIMULATION
    	          Steps_Next_State=Steps_sendingdata_512B;
    	      `else
		          Steps_Next_State=Steps_receiving_resp_4CMD24;
		      `endif
	      else 
		      Steps_Next_State=Steps_tuning_cmd_w;        
		end
		Steps_receiving_resp_4CMD24:begin
		   if(HS400E_Response_received)
		      Steps_Next_State=Steps_check_resp_4CMD24;
		   else
		      Steps_Next_State=Steps_receiving_resp_4CMD24;
		end
		Steps_check_resp_4CMD24:begin
            if(HS400E_Error_CMD24=='b0)
		      if(Timer2==7'b001_0000)
		        Steps_Next_State=Steps_sendingdata_512B;
			  else
			   Steps_Next_State=Steps_check_resp_4CMD24;
		   else
		      if(Timer2==7'b001_0000)
		        Steps_Next_State=Steps_sending_CMD24;
			  else
			   Steps_Next_State=Steps_check_resp_4CMD24;			   
        end		
		Steps_sendingdata_512B:begin
           if(Steps_sending_data_end)
		      Steps_Next_State=Steps_receiving_CRC_status;
		   else
		      Steps_Next_State=Steps_sendingdata_512B;
        end		
		Steps_receiving_CRC_status:begin
		    if(HS400E_crc16_status_end)
				Steps_Next_State=Steps_check_CRC_status;
			else
				Steps_Next_State=Steps_receiving_CRC_status;
		end
		Steps_check_CRC_status:begin
 		   if(HS400E_Received_crc16_status==CRC_STATUS_RIGHT)
		      if(Device_Ready)
		        Steps_Next_State=Steps_write_right;
			  else
			   Steps_Next_State=Steps_check_CRC_status;
		   else
			   Steps_Next_State=Steps_write_wrong;           
        end	
		Steps_write_right:begin
			if(write_end_rece)
		        Steps_Next_State=Steps_delay_16cc;
			else
				Steps_Next_State=Steps_write_right;
		end
		Steps_write_wrong:begin
				Steps_Next_State=Steps_sending_CMD24;
		end
        Steps_sending_CMD17:begin
    	      if(HS400E_Cmd_transfer_end)
		          Steps_Next_State=Steps_receiving_data;
	      else 
		      Steps_Next_State=Steps_sending_CMD17; 
        end 
		Steps_tuning_cmd_r:begin
			if(HS400E_Cmd_transfer_end)
		          Steps_Next_State=Steps_receiving_data;
	      else 
		      Steps_Next_State=Steps_tuning_cmd_r; 
        end 
		
        Steps_receiving_data:begin
             if(Data_received)
			   Steps_Next_State=Steps_check_received_data;
			else
			   Steps_Next_State= Steps_receiving_data;           
        end 		
        Steps_check_received_data:begin
		    if(crc16_check_result) // not passed, transimission incorrect.
			begin
				if(Finished_tuning)
					Steps_Next_State=Steps_sending_CMD17;
				else
					Steps_Next_State=Steps_tap_inc;
			end
			else // 0 indicates check passed.
			begin
				if(Finished_tuning)
					Steps_Next_State=Steps_data_right;
				else
					Steps_Next_State=Steps_tuning_right;
			   
			end
        end
		Steps_tap_inc:begin
			Steps_Next_State=Steps_tuning_cmd_r;
		end
		Steps_data_right:begin
			Steps_Next_State=Steps_fifo_write;
		end
		Steps_fifo_write:begin
			if(fifo_wr_end)
				Steps_Next_State=Steps_fifo_complete;
			else
				Steps_Next_State=Steps_fifo_write;
		end
		Steps_fifo_complete:begin
			Steps_Next_State=Steps_delay_16cc;
		end
		Steps_tuning_right:begin
			Steps_Next_State=Steps_delay_16cc;
		end
		Steps_halt:begin
		   Steps_Next_State=Steps_halt;
		end	
		
		default:begin
			Steps_Next_State=Steps_halt;
		end
	endcase
end


always@(posedge clk_200M)
begin
	case(Steps_Next_State)
		Steps_delay_16cc:begin
		    HS400E_Transmission_dir<=1'b0;
			HS400E_start_transfer_cmd<=1'b0;
			HS400E_Resp_length<='d47;
			HS400E_device_cmd_tobe_sent<='b0;
			HS400E_start_receiving_resp<=1'b0;
            Timer2Start<=1'b1;
			Steps_start_receiving_data<=1'b0;
		    Steps_start_sending_data<=1'b0;
		    HS400E_start_receiving_crc_status<=1'b0;
			HS400E_write_end<=1'b0;
			HS400E_read_end <= 1'b0;
			write_buf_en <=1'b0;
			data_source_select<= 1'b0;
			fifo_wr_start<=1'b0;
        end	
		Steps_idle:begin
		    HS400E_Transmission_dir<=1'b0;
			HS400E_start_transfer_cmd<=1'b0;
			HS400E_Resp_length<='d47;
			HS400E_device_cmd_tobe_sent<='b0;
			HS400E_start_receiving_resp<=1'b0;
			Timer2Start<=1'b0;
			Steps_start_receiving_data<=1'b0;
			Steps_start_sending_data<=1'b0;
			HS400E_start_receiving_crc_status<=1'b0;
			HS400E_write_end<=1'b0;
			HS400E_read_end <= 1'b0;
			write_buf_en <=1'b0;
			data_source_select<= 1'b0;
			fifo_wr_start<=1'b0;
		end

		/*
		Steps_sending_CMD8:begin
			HS400E_Transmission_dir<=1'b0;
			HS400E_start_transfer_cmd<=1'b1;
			HS400E_Resp_length<='d47;
			HS400E_device_cmd_tobe_sent<=CMD8;
			HS400E_start_receiving_resp<=1'b0;
            Timer2Start<=1'b0;	   
			Steps_start_receiving_data<=1'b0;			
		end
        Steps_receiving_EXT_CSD:begin
			HS400E_Transmission_dir<=1'b1;
			HS400E_start_transfer_cmd<=1'b0;
			HS400E_Resp_length<='d47;
			HS400E_device_cmd_tobe_sent<='b0;
			HS400E_start_receiving_resp<=1'b1;
            Timer2Start<=1'b0;	   
			Steps_start_receiving_data<=1'b1;		
		end
		Steps_halt:begin
			HS400E_Transmission_dir<=1'b0;
			HS400E_start_transfer_cmd<=1'b0;
			HS400E_Resp_length<='d47;
			HS400E_device_cmd_tobe_sent<='b0;
			HS400E_start_receiving_resp<=1'b0;
            Timer2Start<=1'b0;	   
			Steps_start_receiving_data<=1'b0;		
		
		end
		
		
		Steps_sending_CMD7:begin
		    HS400E_Transmission_dir<=1'b0;
			HS400E_start_transfer_cmd<=1'b1;
			HS400E_Resp_length<='d47;
			HS400E_device_cmd_tobe_sent<=HS400E_CMD7;
			HS400E_start_receiving_resp<=1'b0;
		    Timer2Start<=1'b0;
			Steps_start_sending_data<=1'b0;
        end		
		Steps_receiving_resp_4CMD7 :begin
           HS400E_Transmission_dir<=1'b1;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b1;
		   Timer2Start<=1'b1;
	       Steps_start_sending_data<=1'b0;
		end
		Steps_check_resp_4CMD7:begin
           HS400E_Transmission_dir<=1'b0;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b1;	
			Steps_start_sending_data<=1'b0;		   
		end	
        */
		Steps_sending_CMD24:begin
           HS400E_Transmission_dir<=1'b0;
		   HS400E_start_transfer_cmd<=1'b1;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<=HS400E_CMD24;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;	
		   HS400E_write_end<=1'b0;
		   HS400E_read_end <= 1'b0;
		   write_buf_en <=1'b0;
		   data_source_select<= data_source_select;
		   fifo_wr_start<=1'b0;
        end     
		Steps_tuning_cmd_w:begin
		   HS400E_Transmission_dir<=1'b0;
		   HS400E_start_transfer_cmd<=1'b1;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<=HS400E_CMD_tuning_w;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;	
		   HS400E_write_end<=1'b0;
		   HS400E_read_end <= 1'b0;
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b1;
		   tap_change_init<=1'b1;
		   tap_change_en<=1'b0;
		   fifo_wr_start<=1'b0;
		end
		Steps_receiving_resp_4CMD24:begin
           HS400E_Transmission_dir<=1'b1;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b1;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;	
		   write_buf_en <=1'b0;
		   data_source_select<= data_source_select;
		   fifo_wr_start<=1'b0;
		end
		Steps_check_resp_4CMD24:begin
           HS400E_Transmission_dir<=1'b0;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b1;
		   	Steps_start_sending_data<=1'b0;
			write_buf_en <=1'b0;
			data_source_select<= data_source_select;
			fifo_wr_start<=1'b0;
        end		
		Steps_sendingdata_512B:begin
           HS400E_Transmission_dir<=1'b0;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<=8'h04;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   	Steps_start_sending_data<=1'b1;
		   	HS400E_start_receiving_crc_status<=1'b0;
			write_buf_en <=1'b1;
			data_source_select<= data_source_select;
			fifo_wr_start<=1'b0;
        end		
		Steps_receiving_CRC_status:begin
           HS400E_Transmission_dir<=1'b1;
           HS400E_start_transfer_cmd<=1'b0;
           HS400E_Resp_length<=8'h04;
           HS400E_device_cmd_tobe_sent<='b0;
           HS400E_start_receiving_resp<=1'b1;
           Timer2Start<=1'b0;
           Steps_start_sending_data<=1'b0;	
           HS400E_start_receiving_crc_status<=1'b1;	   
		   write_buf_en <=1'b1;
		   data_source_select<= 1'b0;
		   fifo_wr_start<=1'b0;
		end
		Steps_check_CRC_status:begin
           HS400E_Transmission_dir<=1'b1;
           HS400E_start_transfer_cmd<=1'b0;
           HS400E_Resp_length<=8'h04;
           HS400E_device_cmd_tobe_sent<='b0;
           HS400E_start_receiving_resp<=1'b0;
           Timer2Start<=1'b0;
           Steps_start_sending_data<=1'b0;
           HS400E_start_receiving_crc_status<=1'b0;
		   write_buf_en <=1'b1;
		   data_source_select<= 1'b0;
		   fifo_wr_start<=1'b0;
        end	
		Steps_write_right:begin
		   HS400E_Transmission_dir<=1'b1;
           HS400E_start_transfer_cmd<=1'b0;
           HS400E_Resp_length<=8'h04;
           HS400E_device_cmd_tobe_sent<='b0;
           HS400E_start_receiving_resp<=1'b0;
           Timer2Start<=1'b0;
           Steps_start_sending_data<=1'b0;
           HS400E_start_receiving_crc_status<=1'b0;
		   HS400E_write_end<=1'b1;
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   fifo_wr_start<=1'b0;
		end
		Steps_write_wrong:begin
		   HS400E_Transmission_dir<=1'b1;
           HS400E_start_transfer_cmd<=1'b0;
           HS400E_Resp_length<=8'h04;
           HS400E_device_cmd_tobe_sent<='b0;
           HS400E_start_receiving_resp<=1'b0;
           Timer2Start<=1'b0;
           Steps_start_sending_data<=1'b0;
           HS400E_start_receiving_crc_status<=1'b0;
		   HS400E_write_end<=1'b0;
		   data_source_select<= 1'b1;
		   write_buf_en <=1'b1;	
		   fifo_wr_start<=1'b0;
		end
        Steps_sending_CMD17:begin
           HS400E_Transmission_dir<=1'b0;
		   HS400E_start_transfer_cmd<=1'b1;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<=HS400E_CMD17;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;	
		   Steps_start_receiving_data<=1'b0;
		   HS400E_write_end<=1'b0;  
           HS400E_read_end <= 1'b0;		   
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   crc16_check_rst<=1'b1;
		   fifo_wr_start<=1'b0;
        end 
		Steps_tuning_cmd_r:begin
		   HS400E_Transmission_dir<=1'b0;
		   HS400E_start_transfer_cmd<=1'b1;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<=HS400E_CMD_tuning_r;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;	
		   Steps_start_receiving_data<=1'b0;
		   HS400E_write_end<=1'b0;  
           HS400E_read_end <= 1'b0;		   
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   crc16_check_rst<=1'b1;
		   tap_change_init<=1'b0;
		   tap_change_en<=1'b0;
		   fifo_wr_start<=1'b0;
		end
        Steps_receiving_data:begin
           HS400E_Transmission_dir<=1'b1;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;
		   Steps_start_receiving_data<=1'b1;
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   crc16_check_rst<=1'b0;
		   fifo_wr_start<=1'b0;
        end 	
        Steps_check_received_data:begin
           HS400E_Transmission_dir<=1'b1;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;
		   Steps_start_receiving_data<=1'b0;
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   crc16_check_rst<=1'b0;
		   fifo_wr_start<=1'b0;
        end
		Steps_tap_inc:begin
		   HS400E_Transmission_dir<=1'b1;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;
		   Steps_start_receiving_data<=1'b0;
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   crc16_check_rst<=1'b0;
		   tap_change_init<=1'b0;
		   tap_change_en<=1'b1;
		   fifo_wr_start<=1'b0;
		end
		Steps_data_right:begin
		   HS400E_Transmission_dir<=1'b1;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;
		   Steps_start_receiving_data<=1'b0;
		   HS400E_read_end <= 1'b0;
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   crc16_check_rst<=1'b0;
		   fifo_wr_start<=1'b1;
		end
		Steps_fifo_write:begin
		   HS400E_Transmission_dir<=1'b1;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;
		   Steps_start_receiving_data<=1'b0;
		   HS400E_read_end <= 1'b0;
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   crc16_check_rst<=1'b0;
		   fifo_wr_start<=1'b1;
		end
		Steps_fifo_complete:begin
		   HS400E_Transmission_dir<=1'b1;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;
		   Steps_start_receiving_data<=1'b0;
		   HS400E_read_end <= 1'b1;
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   crc16_check_rst<=1'b0;
		   fifo_wr_start<=1'b0;
		end
		Steps_tuning_right:begin
		   HS400E_Transmission_dir<=1'b1;
		   HS400E_start_transfer_cmd<=1'b0;
		   HS400E_Resp_length<='d47;
		   HS400E_device_cmd_tobe_sent<='b0;
		   HS400E_start_receiving_resp<=1'b0;
		   Timer2Start<=1'b0;
		   Steps_start_sending_data<=1'b0;
		   Steps_start_receiving_data<=1'b0;
		   HS400E_read_end <= 1'b1;
		   write_buf_en <=1'b0;
		   data_source_select<= 1'b0;
		   crc16_check_rst<=1'b0;
		   tap_change_init<=1'b0;
		   tap_change_en<=1'b0;
		   fifo_wr_start<=1'b0;
		end
		Steps_halt:begin
           HS400E_Transmission_dir<=1'b0;
           HS400E_start_transfer_cmd<=1'b0;
           HS400E_Resp_length<='d47;
           HS400E_device_cmd_tobe_sent<='b0;
           HS400E_start_receiving_resp<=1'b0;
           Timer2Start<=1'b0;
           Steps_start_sending_data<=1'b0;	
           HS400E_start_receiving_crc_status<=1'b0;	
		   HS400E_write_end<=1'b0;	
		   HS400E_read_end <= 1'b0;		 
		   write_buf_en <=1'b0;	
		   data_source_select<= 1'b0;	
		   fifo_wr_start<=1'b0;		   
		end
		
		default:begin
		
		end
	endcase
end
/******************************END**********************************************END**************************************************************/
/**********************Command Transfer Logic Under HS400 Enhanced Strobe mode*******************************************************************/
 wire [6:0]HS400E_CRC_out;
 reg [9:0] HS400E_Cmd_CRC;
 reg HS400E_CRC_en;
 reg HS400E_CRC_rst;
 reg HS400E_Cmd_info_bit;
 reg HS400E_Cmd_info_bit_out;
 
 reg [5:0] HS400E_Cmd_bit_counter=6'b0;
 reg [39:0] HS400E_device_cmd_temp_40;
 

 always @( posedge clk_200M)
 begin
    if(HS400E_start_transfer_cmd) begin
         if( HS400E_Cmd_bit_counter< 'h0c) begin
            HS400E_device_cmd_temp_40<=HS400E_device_cmd_tobe_sent;
            HS400E_Device_cmd_out<=1'b1;
		    HS400E_Cmd_CRC<={HS400E_CRC_out,3'b111};
		    HS400E_CRC_en<=1'b0;
		    HS400E_CRC_rst<=1'b0;
		    HS400E_Cmd_info_bit<=1'b1;
		    HS400E_Cmd_info_bit_out<=1'b1;
         end
         else if(HS400E_Cmd_bit_counter<'h34)  begin
          HS400E_device_cmd_temp_40<=HS400E_device_cmd_temp_40<<1'b1;
          HS400E_Cmd_info_bit<=HS400E_device_cmd_temp_40[39];
		  HS400E_Cmd_info_bit_out<=HS400E_Cmd_info_bit;
		  HS400E_Device_cmd_out<=HS400E_Cmd_info_bit_out;
		  HS400E_Cmd_CRC<={HS400E_CRC_out,3'b111};
		  HS400E_CRC_en<=1'b1;
		  HS400E_CRC_rst<=1'b0;
         end
	   else if(HS400E_Cmd_bit_counter<'h36)begin
	      HS400E_Cmd_CRC<={HS400E_CRC_out,3'b111};
		  HS400E_Cmd_info_bit_out<=HS400E_Cmd_info_bit;
		  HS400E_Device_cmd_out<=HS400E_Cmd_info_bit_out;
	      HS400E_Cmd_info_bit<=1'b0;
		  HS400E_CRC_en<=1'b0;
		  HS400E_CRC_rst<=1'b0;
	   end
	   else begin
	        HS400E_Cmd_CRC<=HS400E_Cmd_CRC<<1'b1;
            HS400E_Device_cmd_out<=HS400E_Cmd_CRC[9];
            HS400E_Cmd_info_bit<=1'b0;
            HS400E_CRC_en<=1'b0;
            HS400E_CRC_rst<=1'b0;
	   end
    end
    else begin
       HS400E_device_cmd_temp_40<='b0;
       HS400E_Device_cmd_out<=1'b1;
	   HS400E_CRC_en<=1'b0;
	   HS400E_CRC_rst<=1'b1;
    end
 end
 // logic for the end flag of a command transfer
 always @( posedge clk_200M)
 begin
       if( & HS400E_Cmd_bit_counter )
          HS400E_Cmd_transfer_end<=1'b1;
       else 
          HS400E_Cmd_transfer_end<=1'b0;
 end
 // generation of a counter(0-63)
 always @( posedge clk_200M)
 begin
       if(HS400E_start_transfer_cmd)
          HS400E_Cmd_bit_counter<=HS400E_Cmd_bit_counter+1'b1;
       else 
          HS400E_Cmd_bit_counter<=48'b0;
 end
 /*************************END****************************************************************************************/
  /***********************Response Receiving Logic under HS400 Enhanced Strobe mode***********************************/
 reg HS400E_Device_resp_temp;
 reg [135:0] HS400E_Received_response;
 reg [7:0] HS400E_Resp_bit_counter;
 reg  HS400E_Response_Arriving;

 always @( posedge clk_200M)
 begin
   if (rst) begin
      HS400E_Device_resp_temp<=1'b1;
   end
   else begin
      if(HS400E_start_receiving_resp) begin 
           HS400E_Device_resp_temp<=device_response_in;      //MARK          MARK    MARK 
         // HS400E_Device_resp_temp<=Test_device_cmd;
      end
      else begin
         HS400E_Device_resp_temp<=1'b1;
      end
   end
 end
  
 always @( posedge clk_200M)
 begin
   if (rst) begin
      HS400E_Response_Arriving<=1'b0;
      HS400E_Response_received<=1'b0;
   end
   else begin
     if(HS400E_Device_resp_temp==1'b0 && HS400E_Resp_bit_counter!=HS400E_Resp_length ) begin
       HS400E_Response_Arriving<=1'b1;
       HS400E_Response_received<=1'b0;
     end
     else begin
       if(HS400E_Resp_bit_counter==HS400E_Resp_length) begin// if HS400E_Device_resp_temp==1'b1 && counter==47 / 135 , which meet the end bit of the response
          HS400E_Response_received<=1'b1;
          HS400E_Response_Arriving<=1'b0;
       end
       else begin
          HS400E_Response_received<=1'b0;
          HS400E_Response_Arriving<=HS400E_Response_Arriving;
       end
     end
   end
 end
 
 always @( posedge clk_200M)
 begin
      if(HS400E_Response_Arriving) begin
          HS400E_Received_response<={HS400E_Received_response[134:0],HS400E_Device_resp_temp};
          HS400E_Received_resp_buff<=HS400E_Received_response;
          HS400E_Resp_bit_counter<=HS400E_Resp_bit_counter+1'b1;
      end
      else begin
          HS400E_Received_response<=136'b0;
          HS400E_Resp_bit_counter<='b0;
      end
 end
/**********************************************END***************END**************WU*************************************************************/
/***************************************** Data CRC16 Status Receiving Logic under HS400 Enhanced Strobe mode***********************************/
reg HS400E_Device_CRC16_temp=1'b1;
reg [2:0] HS400E_crc16_cnter=3'b000;
reg HS400E_crc16_cnter_en =1'b0;


 always @( posedge clk_200M)
begin
     if(HS400E_start_receiving_crc_status) begin 
          HS400E_Device_CRC16_temp<=Device_data_bus_idealy[0];      //MARK          MARK    MARK 
     end
     else begin
        HS400E_Device_CRC16_temp<=1'b1;
     end
end

 always @( posedge clk_200M)
begin
  if(HS400E_crc16_cnter==3'h3) begin
      HS400E_crc16_status_end<=1'b1;
      HS400E_crc16_cnter_en<=1'b0;
  end
  else if(HS400E_Device_CRC16_temp==1'b0 && HS400E_crc16_cnter==3'b000) begin
        HS400E_crc16_status_end<=1'b0;
        HS400E_crc16_cnter_en<=1'b1;
  end
  else begin
        HS400E_crc16_status_end<=1'b0;
  end
  
end

 always @( posedge clk_200M)
begin
  if(HS400E_crc16_cnter_en) begin
        HS400E_Received_crc16_status<= {HS400E_Received_crc16_status[2:0],HS400E_Device_CRC16_temp};
        HS400E_crc16_cnter<=HS400E_crc16_cnter+1'b1;
  end
  else if(HS400E_start_receiving_crc_status==1'b0) begin
        HS400E_crc16_cnter<=3'b000;
  end
end
/**********************************************END*************END*******************************************************************************/
/******************Data Sending Logic under HS400 Enhanced Strobe mode **************************************************************************/
reg  [7:0] back_up_addr;  // input wire [7 : 0] addra
wire [15:0] back_up_out;  // output wire [15 : 0] douta

reg Steps_rd_data_fifo_en;
reg [15:0] Steps_fifo_data_16;
wire [15:0] fifo_data_16;
reg [8:0] steps_sending_data_counter;
reg Steps_crc16_rst;
reg [15:0] Device_data_info_bits=16'hffff;
reg [15:0] Device_data_info_bits_delay1cc=16'hffff;
wire [15:0] Steps_crc16_out_0 ;
wire [15:0] Steps_crc16_out_1 ;
wire [15:0] Steps_crc16_out_2 ;
wire [15:0] Steps_crc16_out_3 ;
wire [15:0] Steps_crc16_out_4 ;
wire [15:0] Steps_crc16_out_5 ;
wire [15:0] Steps_crc16_out_6 ;
wire [15:0] Steps_crc16_out_7 ;
wire [15:0] Steps_crc16_out_8 ;
wire [15:0] Steps_crc16_out_9 ;
wire [15:0] Steps_crc16_out_10;
wire [15:0] Steps_crc16_out_11;
wire [15:0] Steps_crc16_out_12;
wire [15:0] Steps_crc16_out_13;
wire [15:0] Steps_crc16_out_14;
wire [15:0] Steps_crc16_out_15;

reg [15:0] Steps_crc16_out_reg_0 ;
reg [15:0] Steps_crc16_out_reg_1 ;
reg [15:0] Steps_crc16_out_reg_2 ;
reg [15:0] Steps_crc16_out_reg_3 ;
reg [15:0] Steps_crc16_out_reg_4 ;
reg [15:0] Steps_crc16_out_reg_5 ;
reg [15:0] Steps_crc16_out_reg_6 ;
reg [15:0] Steps_crc16_out_reg_7 ;
reg [15:0] Steps_crc16_out_reg_8 ;
reg [15:0] Steps_crc16_out_reg_9 ;
reg [15:0] Steps_crc16_out_reg_10;
reg [15:0] Steps_crc16_out_reg_11;
reg [15:0] Steps_crc16_out_reg_12;
reg [15:0] Steps_crc16_out_reg_13;
reg [15:0] Steps_crc16_out_reg_14;
reg [15:0] Steps_crc16_out_reg_15;

//reg  [7:0] back_up_addr;  // input wire [7 : 0] addra

//wire [15:0] back_up_out;  // output wire [15 : 0] douta

always@(*)
begin
    if(data_source_select == 0)
    begin
	   Steps_fifo_data_16 = fifo_data_16;
    end
    else
    begin
	   Steps_fifo_data_16 = back_up_out;
    end
end
/*
reg [8:0] first_addr;

always @( posedge clk_200M)
begin
	if(Steps_rd_data_fifo_en||write_data_again_en)
	begin
		first_addr <= first_addr+1;
	end
	else
	begin
		first_addr <= 0;
	
	end
end
*/

reg write_again_addr_en;
always @( posedge clk_200M)
begin
	if(Steps_rd_data_fifo_en)
	begin
		back_up_addr <= back_up_addr + 1;
		/*if(first_addr)
		begin
			back_up_addr <= back_up_addr + 1;
		end	
		else
		begin
			back_up_addr <= 0;
		end*/
	end
	else if(write_again_addr_en)
	begin
		back_up_addr <= back_up_addr + 1;
		/*if(first_addr)
		begin
			back_up_addr <= back_up_addr + 1;
		end	
		else
		begin
			back_up_addr <= 0;
		end*/
	end
	else
	begin
		back_up_addr <= 0;
	
	end
end

always @ (posedge clk_200M)
begin
	if(data_source_select&&Steps_start_sending_data)
	begin
		write_again_addr_en<=1'b1;
	end
	else
	begin
		write_again_addr_en<=1'b0;
	end
end

 always @( posedge clk_200M)
 begin
    if(steps_sending_data_counter=='b0) begin
	   Device_data_info_bits<=16'hffff;
	   Device_data_info_bits_delay1cc<=Device_data_info_bits;
	   Device_data_bus_out<=Device_data_info_bits_delay1cc;
	   Steps_sending_data_end<=1'b0;
	   Steps_rd_data_fifo_en<=1'b0;
	   write_data_again_en<= 1'b0;
	   Steps_crc16_rst<=1'b1;
	   Steps_crc16_out_reg_0 <= Steps_crc16_out_0 ;
	   Steps_crc16_out_reg_1 <= Steps_crc16_out_1 ;
	   Steps_crc16_out_reg_2 <= Steps_crc16_out_2 ;
	   Steps_crc16_out_reg_3 <= Steps_crc16_out_3 ;
	   Steps_crc16_out_reg_4 <= Steps_crc16_out_4 ;
	   Steps_crc16_out_reg_5 <= Steps_crc16_out_5 ;
	   Steps_crc16_out_reg_6 <= Steps_crc16_out_6 ;
	   Steps_crc16_out_reg_7 <= Steps_crc16_out_7 ;
	   Steps_crc16_out_reg_8 <= Steps_crc16_out_8 ;
	   Steps_crc16_out_reg_9 <= Steps_crc16_out_9 ;
	   Steps_crc16_out_reg_10<= Steps_crc16_out_10;
	   Steps_crc16_out_reg_11<= Steps_crc16_out_11;
	   Steps_crc16_out_reg_12<= Steps_crc16_out_12;
	   Steps_crc16_out_reg_13<= Steps_crc16_out_13;
	   Steps_crc16_out_reg_14<= Steps_crc16_out_14;
	   Steps_crc16_out_reg_15<= Steps_crc16_out_15;
	end
    else if(steps_sending_data_counter<'d2) begin
	   Device_data_info_bits<=16'h0000;
	   Device_data_info_bits_delay1cc<=Device_data_info_bits;
	   Device_data_bus_out<=Device_data_info_bits_delay1cc;
	   Steps_sending_data_end<=1'b0;
	   Steps_rd_data_fifo_en<=1'b1;
	   if(data_source_select)
	   begin
			write_data_again_en<= 1'b1;
	   end
	   else
	   begin
			write_data_again_en<= 1'b0;
	   end
	   Steps_crc16_rst<=1'b0;
	   Steps_crc16_out_reg_0 <= Steps_crc16_out_0 ;
	   Steps_crc16_out_reg_1 <= Steps_crc16_out_1 ;
	   Steps_crc16_out_reg_2 <= Steps_crc16_out_2 ;
	   Steps_crc16_out_reg_3 <= Steps_crc16_out_3 ;
	   Steps_crc16_out_reg_4 <= Steps_crc16_out_4 ;
	   Steps_crc16_out_reg_5 <= Steps_crc16_out_5 ;
	   Steps_crc16_out_reg_6 <= Steps_crc16_out_6 ;
	   Steps_crc16_out_reg_7 <= Steps_crc16_out_7 ;
	   Steps_crc16_out_reg_8 <= Steps_crc16_out_8 ;
	   Steps_crc16_out_reg_9 <= Steps_crc16_out_9 ;
	   Steps_crc16_out_reg_10<= Steps_crc16_out_10;
	   Steps_crc16_out_reg_11<= Steps_crc16_out_11;
	   Steps_crc16_out_reg_12<= Steps_crc16_out_12;
	   Steps_crc16_out_reg_13<= Steps_crc16_out_13;
	   Steps_crc16_out_reg_14<= Steps_crc16_out_14;
	   Steps_crc16_out_reg_15<= Steps_crc16_out_15;
	end
	else if (steps_sending_data_counter<'d257) begin
	   Device_data_info_bits<=Steps_fifo_data_16;
	   Device_data_info_bits_delay1cc<=Device_data_info_bits;
	   Device_data_bus_out<=Device_data_info_bits_delay1cc;
	   Steps_sending_data_end<=1'b0;
	   Steps_rd_data_fifo_en<=1'b1;
	   if(data_source_select)
	   begin
			write_data_again_en<= 1'b1;
	   end
	   else
	   begin
			write_data_again_en<= 1'b0;
	   end
       Steps_crc16_rst<=1'b0;
	   Steps_crc16_out_reg_0 <= Steps_crc16_out_0 ;
	   Steps_crc16_out_reg_1 <= Steps_crc16_out_1 ;
	   Steps_crc16_out_reg_2 <= Steps_crc16_out_2 ;
	   Steps_crc16_out_reg_3 <= Steps_crc16_out_3 ;
	   Steps_crc16_out_reg_4 <= Steps_crc16_out_4 ;
	   Steps_crc16_out_reg_5 <= Steps_crc16_out_5 ;
	   Steps_crc16_out_reg_6 <= Steps_crc16_out_6 ;
	   Steps_crc16_out_reg_7 <= Steps_crc16_out_7 ;
	   Steps_crc16_out_reg_8 <= Steps_crc16_out_8 ;
	   Steps_crc16_out_reg_9 <= Steps_crc16_out_9 ;
	   Steps_crc16_out_reg_10<= Steps_crc16_out_10;
	   Steps_crc16_out_reg_11<= Steps_crc16_out_11;
	   Steps_crc16_out_reg_12<= Steps_crc16_out_12;
	   Steps_crc16_out_reg_13<= Steps_crc16_out_13;
	   Steps_crc16_out_reg_14<= Steps_crc16_out_14;
	   Steps_crc16_out_reg_15<= Steps_crc16_out_15;
    end
 	else if (steps_sending_data_counter<'d260) begin
       Device_data_info_bits<=Steps_fifo_data_16;
       Device_data_info_bits_delay1cc<=Device_data_info_bits;
       Device_data_bus_out<=Device_data_info_bits_delay1cc;
       Steps_sending_data_end<=1'b0;
	   Steps_rd_data_fifo_en<=1'b0;
	   write_data_again_en<= 1'b0;
	  
       Steps_crc16_rst<=1'b0;
       Steps_crc16_out_reg_0 <= Steps_crc16_out_0 ;
       Steps_crc16_out_reg_1 <= Steps_crc16_out_1 ;
       Steps_crc16_out_reg_2 <= Steps_crc16_out_2 ;
       Steps_crc16_out_reg_3 <= Steps_crc16_out_3 ;
       Steps_crc16_out_reg_4 <= Steps_crc16_out_4 ;
       Steps_crc16_out_reg_5 <= Steps_crc16_out_5 ;
       Steps_crc16_out_reg_6 <= Steps_crc16_out_6 ;
       Steps_crc16_out_reg_7 <= Steps_crc16_out_7 ;
       Steps_crc16_out_reg_8 <= Steps_crc16_out_8 ;
       Steps_crc16_out_reg_9 <= Steps_crc16_out_9 ;
       Steps_crc16_out_reg_10<= Steps_crc16_out_10;
       Steps_crc16_out_reg_11<= Steps_crc16_out_11;
       Steps_crc16_out_reg_12<= Steps_crc16_out_12;
       Steps_crc16_out_reg_13<= Steps_crc16_out_13;
       Steps_crc16_out_reg_14<= Steps_crc16_out_14;
       Steps_crc16_out_reg_15<= Steps_crc16_out_15;
    end   
	else if (steps_sending_data_counter<'d276) begin
	   Device_data_bus_out<={Steps_crc16_out_reg_15[15],Steps_crc16_out_reg_14[15],Steps_crc16_out_reg_13[15],
	                         Steps_crc16_out_reg_12[15],Steps_crc16_out_reg_11[15],Steps_crc16_out_reg_10[15],
							 Steps_crc16_out_reg_9[15] ,Steps_crc16_out_reg_8[15] ,Steps_crc16_out_reg_7[15],
							 Steps_crc16_out_reg_6[15] ,Steps_crc16_out_reg_5[15] ,Steps_crc16_out_reg_4[15],
							 Steps_crc16_out_reg_3[15] ,Steps_crc16_out_reg_2[15] ,Steps_crc16_out_reg_1[15],
							 Steps_crc16_out_reg_0[15]
							 };
		
	   Steps_sending_data_end<=1'b0;
	   Steps_rd_data_fifo_en<=1'b0;
	   write_data_again_en<= 1'b0;
	   
	   Steps_crc16_rst<=1'b0;
	   
	   Steps_crc16_out_reg_0 <= Steps_crc16_out_reg_0 <<1'b1;
	   Steps_crc16_out_reg_1 <= Steps_crc16_out_reg_1 <<1'b1;
	   Steps_crc16_out_reg_2 <= Steps_crc16_out_reg_2 <<1'b1;
	   Steps_crc16_out_reg_3 <= Steps_crc16_out_reg_3 <<1'b1;
	   Steps_crc16_out_reg_4 <= Steps_crc16_out_reg_4 <<1'b1;
	   Steps_crc16_out_reg_5 <= Steps_crc16_out_reg_5 <<1'b1;
	   Steps_crc16_out_reg_6 <= Steps_crc16_out_reg_6 <<1'b1;
	   Steps_crc16_out_reg_7 <= Steps_crc16_out_reg_7 <<1'b1;
	   Steps_crc16_out_reg_8 <= Steps_crc16_out_reg_8 <<1'b1;
	   Steps_crc16_out_reg_9 <= Steps_crc16_out_reg_9 <<1'b1;
	   Steps_crc16_out_reg_10<= Steps_crc16_out_reg_10<<1'b1;
	   Steps_crc16_out_reg_11<= Steps_crc16_out_reg_11<<1'b1;
	   Steps_crc16_out_reg_12<= Steps_crc16_out_reg_12<<1'b1;
	   Steps_crc16_out_reg_13<= Steps_crc16_out_reg_13<<1'b1;
	   Steps_crc16_out_reg_14<= Steps_crc16_out_reg_14<<1'b1;
	   Steps_crc16_out_reg_15<= Steps_crc16_out_reg_15<<1'b1;
	end
	else if (steps_sending_data_counter<'d277) begin
	   Device_data_bus_out<=16'hffff;
		write_data_again_en<= 1'b0;
		
	   Steps_sending_data_end<=1'b0;
	   Steps_rd_data_fifo_en<=1'b0;
	   Steps_crc16_rst<=1'b0;	   
	end	
	else begin
	  Device_data_bus_out<=16'hffff;
	  Device_data_info_bits<=16'hffff;
	  Device_data_info_bits_delay1cc<=16'hffff;
	  Steps_sending_data_end<=1'b1;
      Steps_rd_data_fifo_en<=1'b0;
	  write_data_again_en<= 1'b0;
	  
	  Steps_crc16_rst<=1'b1;

    end
 end 


 always @( posedge clk_200M)
 begin
      if(Steps_start_sending_data)
	     steps_sending_data_counter<=steps_sending_data_counter+1'b1;
	  else
	     steps_sending_data_counter<='b0;
 end 
 
  CRC16 crc16_inst0(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[0]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_0)
	);
  CRC16 crc16_inst1(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[1]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_1)
	);
  CRC16 crc16_inst2(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[2]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_2)
	);
  CRC16 crc16_inst3(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[3]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_3)
	);
  CRC16 crc16_inst4(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[4]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_4)
	);
  CRC16 crc16_inst5(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[5]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_5)
	);
  CRC16 crc16_inst6(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[6]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_6)
	);
  CRC16 crc16_inst7(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[7]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_7)
	);
  CRC16 crc16_inst8(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[8]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_8)
	);
  CRC16 crc16_inst9(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[9]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_9)
	);
  CRC16 crc16_inst10(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[10]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_10)
	);
  CRC16 crc16_inst11(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[11]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_11)
	);
  CRC16 crc16_inst12(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[12]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_12)
	);
  CRC16 crc16_inst13(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[13]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_13)
	);
  CRC16 crc16_inst14(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[14]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_14)
	);
  CRC16 crc16_inst15(
    .clk(clk_200M),
    .BITVAL(Steps_fifo_data_16[15]),                          // Next input bit
    .Enable(Steps_rd_data_fifo_en||write_data_again_en),
    .rst(Steps_crc16_rst),                            // Init CRC value
    .CRC(Steps_crc16_out_15)
	);
/**********************************************END***************END**************WU*************************************************************/
/******************Data Receiving Logic under HS400 Enhanced Strobe mode********************************************/
 //Databus=1 bit, Data_size=512 bytes  
   (* dont_touch = "true" *) reg [7:0] Device_data_temp_p;
   (* dont_touch = "true" *) reg [7:0] Device_data_temp_n;
   (* dont_touch = "true" *) wire [15:0] Device_data_temp;
   assign Device_data_temp = {Device_data_temp_p,Device_data_temp_n};
 //reg [135:0] Received_response;
 
 reg [8:0] Data_bit_counter;
 
 always @( posedge clk_200M)
 begin
   if (rst) begin
      Device_data_temp_p<=8'hff;
      Device_data_temp_n<=8'hff;
   end
   else  begin
      if(Steps_start_receiving_data) begin
          Device_data_temp_p<=Device_data_bus_in_p;      //MARK          MARK    MARK 
		  Device_data_temp_n<=Device_data_bus_in_n;
	     
      end
      else begin
         Device_data_temp_p<=8'hff;
		 Device_data_temp_n<=8'hff;
      end
   end
  end
  
 always @( posedge clk_200M)
 begin
   if (rst) begin
      Data_Arriving<=1'b0;
      Data_received<=1'b0;
   end
   else  begin
     if((Device_data_temp_p==8'h00)&&(Data_Arriving == 0)) begin
       Data_Arriving<=1'b1;
       Data_received<=1'b0;
     end
     else begin
       if(Data_bit_counter=='d271) begin// if Device_resp_temp==1'b1 && counter==47 / 135 , which meet the end bit of the response
          Data_received<=1'b1;
          Data_Arriving<=1'b0;
       end
       else begin
          Data_received<=1'b0;
          Data_Arriving<=Data_Arriving;
       end
     end
   end
 end
 
 always @( posedge clk_200M)
 begin
      if(Data_Arriving) begin
          Data_bit_counter<=Data_bit_counter+1'b1;
      end
      else begin
          Data_bit_counter<='b0;
      end
 end
 
 wire [15:0] crc16_check_result_0;
 wire [15:0] crc16_check_result_1;
 wire [15:0] crc16_check_result_2;
 wire [15:0] crc16_check_result_3;
 wire [15:0] crc16_check_result_4;
 wire [15:0] crc16_check_result_5;
 wire [15:0] crc16_check_result_6;
 wire [15:0] crc16_check_result_7;
 wire [15:0] crc16_check_result_8;
 wire [15:0] crc16_check_result_9;
 wire [15:0] crc16_check_result_10;
 wire [15:0] crc16_check_result_11;
 wire [15:0] crc16_check_result_12;
 wire [15:0] crc16_check_result_13;
 wire [15:0] crc16_check_result_14;
 wire [15:0] crc16_check_result_15;
 
 
 wire crc16_check_and0= (|crc16_check_result_0) | (|crc16_check_result_1) | (|crc16_check_result_2) | (|crc16_check_result_3); 
 wire crc16_check_and1= (|crc16_check_result_4) | (|crc16_check_result_5)| (|crc16_check_result_6) | (|crc16_check_result_7);
 wire crc16_check_and2= (|crc16_check_result_8) | (|crc16_check_result_9) | (|crc16_check_result_10) | (|crc16_check_result_11); 
 wire crc16_check_and3= (|crc16_check_result_12) | (|crc16_check_result_13)| (|crc16_check_result_14) | (|crc16_check_result_15);
 CRC16_Check crc16_check_inst_0(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_p[0]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_0)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_1(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_p[1]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_1)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_2(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_p[2]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_2)                             // Current output CRC value
								);	
 CRC16_Check crc16_check_inst_3(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_p[3]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_3)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_4(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_p[4]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_4)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_5(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_p[5]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_5)                             // Current output CRC value
								);	
 CRC16_Check crc16_check_inst_6(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_p[6]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_6)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_7(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_p[7]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_7)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_8(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_n[0]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_8)                             // Current output CRC value
								);	
 CRC16_Check crc16_check_inst_9(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_n[1]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_9)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_10(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_n[2]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_10)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_11(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_n[3]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_11)                             // Current output CRC value
								);	
 CRC16_Check crc16_check_inst_12(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_n[4]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_12)                             // Current output CRC value
								);	
 CRC16_Check crc16_check_inst_13(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_n[5]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_13)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_14(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_n[6]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_14)                             // Current output CRC value
								);
 CRC16_Check crc16_check_inst_15(
								.clk(clk_200M),
								.BITVAL(Device_data_temp_n[7]),                          // Next input bit
								.Enable(Data_Arriving),
								.rst(crc16_check_rst),                            // Init CRC value
								.CRC(crc16_check_result_15)                             // Current output CRC value
								);	
							
 /*************************END****************************************************************************************/
 
  /******************Read fifo Data writing Logic under HS400 Enhanced Strobe mode********************************************/
  
 reg [8:0] Fifo_bit_counter;
   
 always @( posedge clk_200M)
 begin
   if (rst) begin
		fifo_wr_end<=1'b0;
		Fifo_bit_counter<='b0;
   end
   else  begin
		if(fifo_wr_start&&(Fifo_bit_counter<'d257)) begin
          Fifo_bit_counter<=Fifo_bit_counter+1'b1;
		  fifo_wr_end<=1'b0;
		end
		else begin
          Fifo_bit_counter<='b0;
		  fifo_wr_end<=1'b1;
		end
   end
 end
 
 always @( posedge clk_200M)
 begin
      
 end
							
 /*************************END****************************************************************************************/
 /******************Final read fifo Data source choice********************************************/
wire [15:0] rd_data_fifo_out; 
reg fifo_MUX;
always@(*)
begin
    if(fifo_MUX == 0)//0:rd_fifo 1:wr_fifo
    begin
	   rd_data_final = rd_data_fifo_out;
    end
    else
    begin
	   rd_data_final = fifo_data_16;
    end
end

always@(posedge clk_200M)
begin
  if(rst)
  begin
  		fifo_MUX<=0;
  end
  else if(Operation_type[0] == 0) 
  begin
        fifo_MUX<=0;
  end
  else begin
		if((Fifo_bit_counter>(32*Sector_offset))&&(Fifo_bit_counter<(32*Sector_offset+33)))
		begin
			fifo_MUX<=1;
		end
		else
		begin
			fifo_MUX<=0;
		end
  end
end 
 /*************************END****************************************************************************************/
 /*****************The main state machine for Operations under Backwords compatibility mode(400kHz here) ****************************************/
always@(posedge clk_20M)
begin
  if(rst)
  		Curr_State<=Power_up_delay;
  else 
        Curr_State<=Next_State;  
end 
 
always@(*)
begin
   Next_State=Power_up_delay;
	case(Curr_State)
	//This is the initial state after system power up.
	//Ask for permittion to reset chip and change to Sync mode.
	  Power_up_delay:begin   // delay 5ns * 2^16=320us to powerup until device is ready to recevie command.
	   if(Powerup_delay_end)
	        Next_State=Reset_device;
	   else 
	        Next_State=Power_up_delay;
	  end
	  Reset_device:begin
	       if(Cmd_transfer_end)
	         Next_State=Delay_16cycle_CMD0to1;                             //   DEBUG    DEBUG 
			//   Next_State=HS400_Ready;
	       else
	         Next_State=Reset_device;
	  end
	  Delay_16cycle_CMD0to1:begin
	    if(Timer1==5'b1_0000)
	      Next_State=Idle_State;
	    else
	      Next_State=Delay_16cycle_CMD0to1;
	  end
	   Idle_State : begin
	      if (Cmd_transfer_end)
	       `ifdef SIMULATION
	           Next_State=HS400_Ready;
	       `else
	         Next_State=Receiving_resp_4CMD1;   //Debug MARK  MARK   
	       `endif
	      else
	         Next_State=Idle_State;
	   end
	   Receiving_resp_4CMD1: begin
	       if(Response_received)
	          Next_State=Check_response;
	       else
	           Next_State=Receiving_resp_4CMD1;
	   end
	   Check_response:begin
	      case (Check_resp_passed)
	      2'b11:  // The device response is positive
	          Next_State=Delay_16cycle_CMD2;
	      2'b10: // The device response is negative, indicating a busy state. Thus, resend CMD1.
	          Next_State=Delay_16cycle_CMD0to1;
	      2'b01: // The device does not support sector addressing 
	          Next_State=Error_state;      
	      2'b00: 
	        Next_State=Check_response; // Stay in this state.
	      default: 
	        Next_State=Check_response; // Stay in this state.
	      endcase
	   end

	   // Identification process 
	   Delay_16cycle_CMD2: begin
	        if(Timer1==5'b1_0000)
	          Next_State=Sending_CMD2;
	        else
	          Next_State=Delay_16cycle_CMD2;
	   end
	   Sending_CMD2:begin
	         if(Cmd_transfer_end)
			    Next_State=Receiving_CID;
			 else
			    Next_State=Sending_CMD2;
			 
	   end
	   Receiving_CID:begin 
	      if(Timer1==5'b1_0000&&Response_Arriving==1'b0)
		      Next_State=Stand_by_state;
          else if(Response_received)
		      Next_State=Next_device;
		  else
		      Next_State=Receiving_CID;
       end
       Next_device:begin
            Next_State=Delay_16cycle_CMD3;
       end		
	   Delay_16cycle_CMD3:begin
	      if(Timer1==5'b1_0000)
		     Next_State=Sending_CMD3;
		  else 
		     Next_State=Delay_16cycle_CMD3;
	   end
	   Sending_CMD3:begin
	         if(Cmd_transfer_end)
			    Next_State=Receiving_resp_4CMD3;
			 else
			    Next_State=Sending_CMD3;	      
	   end
	   Receiving_resp_4CMD3:begin
          if(Response_received)
		      Next_State=Check_Device_status;
		  else
		      Next_State=Receiving_resp_4CMD3;
       end	      
	   
	   Check_Device_status:begin
	      if(Error_CMD3=='b0)
		     Next_State=Delay_16cycle_CMD2;
		  else  
		     Next_State=Delay_16cycle_CMD3;
		
	   end
	   Stand_by_state:begin
		      Next_State=Delay_16cycle_CMD7;
	   end
	   
	  // Activation of HS400 Process
	   Delay_16cycle_CMD7:begin
	       if(Device_selection_counter>DEVICE_NUMBER) begin
	            if(Timer1==5'b1_0000)
		            Next_State=HS400_Ready;
		        else 
		           Next_State=Delay_16cycle_CMD7;
		   end
		   else begin
		      if(Timer1==5'b1_0000)
			      Next_State=Sending_CMD7;
			  else
			      Next_State=Delay_16cycle_CMD7;
		   end 
	   end
	   Sending_CMD7:begin
	      if(Cmd_transfer_end)
		     Next_State=Receiving_resp_4CMD7;
	      else 
		      Next_State=Sending_CMD7;
	   end
	   Receiving_resp_4CMD7:begin
          if(Response_received)
		      Next_State=Check_resp_4CMD7;
		  else
		      Next_State=Receiving_resp_4CMD7;	      
	   end
	   Check_resp_4CMD7:begin
	      if(Error_CMD7=='b0) begin
		       if (Timer1==5'b1_0000 )
		           Next_State=Set_timing_HSmode;
			   else 
			      Next_State=Check_resp_4CMD7;
		  end       
		  else begin
		       if (Timer1==5'b1_0000 )
		           Next_State=Stand_by_state;
			   else 
			      Next_State=Check_resp_4CMD7;   
          end
	   end
	   Set_timing_HSmode:begin //CMD6
 	      if(Cmd_transfer_end)
		     Next_State=Receiving_resp_4CMD6_HS;
	      else 
		      Next_State=Set_timing_HSmode;         
       end 
       Receiving_resp_4CMD6_HS:begin
           if(Response_received)
		      Next_State=Check_resp_4CMD6_HS;
		  else
		      Next_State=Receiving_resp_4CMD6_HS;         
       end	  
       Check_resp_4CMD6_HS:begin
			  if(Error_CMD6=='b0) begin
				   if (Timer1==5'b1_0000 )
					   Next_State=Set_bus_width_x8;
				   else 
					  Next_State=Check_resp_4CMD6_HS;
			  end       
			  else begin
				   if (Timer1==5'b1_0000 )
					   Next_State=Set_timing_HSmode;
				   else 
					  Next_State=Check_resp_4CMD6_HS;   
			  end		
       end 	 
       Set_bus_width_x8:begin
  	      if(Cmd_transfer_end)
		     Next_State=Receiving_resp_4CMD6_BW;
	      else 
		      Next_State=Set_bus_width_x8;           
       end	
	   Receiving_resp_4CMD6_BW:begin
           if(Response_received)
		      Next_State=Check_resp_4CMD6_BW;
		  else
		      Next_State=Receiving_resp_4CMD6_BW;	    
	   end
	   Check_resp_4CMD6_BW:begin
			  if(Error_CMD6=='b0) begin
				   if (Timer1==5'b1_0000 )
					   Next_State=Set_timing_HS400;
				   else 
					  Next_State=Check_resp_4CMD6_BW;
			  end       
			  else begin
				   if (Timer1==5'b1_0000 )
					   Next_State=Set_bus_width_x8;
				   else 
					  Next_State=Check_resp_4CMD6_BW;   
			  end  		
	   end
	   Set_timing_HS400:begin
  	      if(Cmd_transfer_end)
		     Next_State=Receiving_resp_4CMD6_HS400;
	      else 
		      Next_State=Set_timing_HS400;	       
	   end
	   Receiving_resp_4CMD6_HS400:begin
	      if(Response_received)
		      Next_State=Check_resp_4CMD6_HS400;
		  else
		      Next_State=Receiving_resp_4CMD6_HS400;	     
	   end
	   Check_resp_4CMD6_HS400:begin
			  if(Error_CMD6=='b0) begin
				   if (Timer1==5'b1_0000 )
					   Next_State=Next_RCA_4_activation;
				   else 
					  Next_State=Check_resp_4CMD6_HS400;
			  end       
			  else begin
				   if (Timer1==5'b1_0000 )
					   Next_State=Set_timing_HS400;
				   else 
					  Next_State=Check_resp_4CMD6_HS400;   
			  end 
	   end
	   Next_RCA_4_activation:begin		  
		     Next_State=Delay_16cycle_CMD7;
	   end
	   HS400_Ready:begin
	      Next_State=HS400_Ready;
	   end 
	   ///////////////////////////
	   Error_state:begin
          Next_State=Error_state;
       end
	   default: begin
	      Next_State=Power_up_delay;
	   end
	endcase
end          

always@(posedge clk_20M)
begin
   if(rst) begin
     Init_Transmission_dir<=1'b0;
     start_transfer_cmd<=1'b0;
     device_cmd_tobe_sent<='b0;
     start_receiving_resp<=1'b0;
     Start_check_resp<=1'b0;
     Timer1Start<=1'b0;
	 Resp_length<='b0;
	 Device_selection_counter<='b0;
	 HS400E_en<=1'b0;
   end
   else begin
     case(Next_State)
     
        Power_up_delay:begin
           // nothing to do in this state, just waiting..........
           Init_Transmission_dir<=1'b0;
           start_transfer_cmd<=1'b0;
		   Resp_length<='b0;
           device_cmd_tobe_sent<='b0;
           start_receiving_resp<=1'b0;
           Start_check_resp<=1'b0;
           Timer1Start<=1'b0;
		   Device_selection_counter<='b0;
		   HS400E_en<=1'b0;
		    
        end
        Reset_device:begin
             Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b1;
			 Resp_length<='d47;
             device_cmd_tobe_sent<=CMD0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;    
              Timer1Start<=1'b0;
			  Device_selection_counter<='b0;
        end
        Delay_16cycle_CMD0to1:begin
            Init_Transmission_dir<=1'b0;
            start_transfer_cmd<=1'b0;
			Resp_length<='d47;
            device_cmd_tobe_sent<='b0;
            start_receiving_resp<=1'b0;
            Start_check_resp<=1'b0;   
             Timer1Start<=1'b1;
        end
        Idle_State : begin
          Init_Transmission_dir<=1'b0;
          start_transfer_cmd<=1'b1;
		  Resp_length<='d47;
          device_cmd_tobe_sent<=CMD1;
          start_receiving_resp<=1'b0;
          Start_check_resp<=1'b0;
          Timer1Start<=1'b0;
        end 
        Receiving_resp_4CMD1:begin
          Init_Transmission_dir<=1'b1;
          start_transfer_cmd<=1'b0;
		  Resp_length<='d47;
          device_cmd_tobe_sent<='b0;
          start_receiving_resp<=1'b1;
            Timer1Start<=1'b0;
        end
        Check_response:begin
          Init_Transmission_dir<=1'b0;
          start_transfer_cmd<=1'b0;
		  Resp_length<='d47;
          device_cmd_tobe_sent<='b0;
          start_receiving_resp<=1'b0;
          Start_check_resp<=1'b1;
            Timer1Start<=1'b0;
        end

		 //Identification process
		Delay_16cycle_CMD2: begin
		     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b1;	
	    end
		Sending_CMD2: begin
		     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b1;
			 Resp_length<='d135;
             device_cmd_tobe_sent<=CMD2;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;			     
		end
	
	    Receiving_CID:begin  
 		     Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d135;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b1;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b1;             
        end  
	   Next_device:begin
 		     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0; 	        
	         Device_selection_counter<=Device_selection_counter+1'b1;
	   end
	    Delay_16cycle_CMD3:begin
 		     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b1;  
			 CID[Device_selection_counter]<={Received_resp_buff[127:1],1'b1};	 
	    end
	   Sending_CMD3:begin
		     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b1;
			 Resp_length<='d47;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;	
 		     device_cmd_tobe_sent<=CMD3;
           			 
	   end
	   Receiving_resp_4CMD3:begin
 		     Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b1;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;             	        
	   end
	   Check_Device_status:begin
 		     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0; 	        
	   end
	   Stand_by_state:begin
 		     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0; 
	         Device_selection_counter<='b1; // RCA=0x0001 by default
	   end	
	   
	   // Activation of HS400 Process
	   Delay_16cycle_CMD7:begin
 		     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b1; 	   
	   end
	   Sending_CMD7:begin
	 		 Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b1;
			 Resp_length<='d47;
             device_cmd_tobe_sent<=CMD7_4ACTIVATION;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;         
	   end  

	    Receiving_resp_4CMD7:begin
 	 		 Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b1;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;              
        end		
	    Check_resp_4CMD7:begin
 	 		 Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b1;
        end		
	    Set_timing_HSmode:begin
  	 		 Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b1;
			 Resp_length<='d47;
             device_cmd_tobe_sent<=CMD6_HS_MODE;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;           
        end		
	    Receiving_resp_4CMD6_HS:begin
    	     Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b1;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;          
        end 		
	    Check_resp_4CMD6_HS:begin
     	     Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b1;          
        end		
	    Set_bus_width_x8:begin
       	     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b1;
			 Resp_length<='d47;
             device_cmd_tobe_sent<=CMD6_BUS_WIDTH_X8;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;         
        end		
	    Receiving_resp_4CMD6_BW:begin
       	     Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b1;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;
        end		
	    Check_resp_4CMD6_BW:begin
       	     Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b1;
        end		
	    Set_timing_HS400:begin
       	     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b1;
			 Resp_length<='d47;
             device_cmd_tobe_sent<=CMD6_HS400_MODE;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;  
        end		
	    Receiving_resp_4CMD6_HS400:begin
         	 Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b1;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;          
        end		 
	    Check_resp_4CMD6_HS400:begin
       	     Init_Transmission_dir<=1'b1;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b1;
        end		
	    Next_RCA_4_activation:begin
       	     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b0;
			 Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;		
             Device_selection_counter<=Device_selection_counter+1'b1;
        end
	    HS400_Ready:begin
       	     Init_Transmission_dir<=1'b0;
             start_transfer_cmd<=1'b0;
             Resp_length<='d47;
             device_cmd_tobe_sent<='b0;
             start_receiving_resp<=1'b0;
             Start_check_resp<=1'b0;
             Timer1Start<=1'b0;  
             HS400E_en<=1'b1;			 
	    end 
        Error_state:begin
            HS400E_en<=1'b0;
        end		
        default: begin
        
        end 
     endcase
   end
 end
 
 
 /********************************END OF STATE MACHINE***************************************************************/
 
 /**********************Command Transfer Logic **********************************************************************/
 wire [6:0] CRC_out;
 reg [7:0] Cmd_CRC;
 reg CRC_en;
 reg CRC_rst;
 reg Cmd_info_bit;
 reg Cmd_info_bit_out;
 always @( posedge clk_20M)
 begin
   if(clk_400K_en) begin
      if(start_transfer_cmd) begin
           if( Cmd_bit_counter< 'h0e) begin
              device_cmd_temp_40<=device_cmd_tobe_sent;
              Init_Device_cmd_out<=1'b1;
			  Cmd_CRC<={CRC_out,1'b1};
			  CRC_en<=1'b0;
			  CRC_rst<=1'b0;
			  Cmd_info_bit<=1'b1;
			  Cmd_info_bit_out<=1'b1;
           end
           else if(Cmd_bit_counter<'h36)  begin
              device_cmd_temp_40<=device_cmd_temp_40<<1'b1;
              Cmd_info_bit<=device_cmd_temp_40[39];
			  Cmd_info_bit_out<=Cmd_info_bit;
			  Init_Device_cmd_out<=Cmd_info_bit_out;
			  Cmd_CRC<={CRC_out,1'b1};
			  CRC_en<=1'b1;
			  CRC_rst<=1'b0;
           end
		   else if(Cmd_bit_counter<'h38)begin
		      Cmd_CRC<={CRC_out,1'b1};
			  Cmd_info_bit_out<=Cmd_info_bit;
			  Init_Device_cmd_out<=Cmd_info_bit_out;
		       Cmd_info_bit<=1'b0;
			  CRC_en<=1'b0;
			  CRC_rst<=1'b0;
		   end
		   else begin
		      Cmd_CRC<=Cmd_CRC<<1'b1;
              Init_Device_cmd_out<=Cmd_CRC[7];
              Cmd_info_bit<=1'b0;
              CRC_en<=1'b0;
              CRC_rst<=1'b0;
		   end
      end
      else begin
         device_cmd_temp_40<='b0;
         Init_Device_cmd_out<=1'b1;
		 CRC_en<=1'b0;
		 CRC_rst<=1'b1;
      end
   end 
 end
 // logic for the end flag of a command transfer
 always @( posedge clk_20M)
 begin
    if(clk_400K_en) begin
       if( & Cmd_bit_counter )
          Cmd_transfer_end<=1'b1;
       else 
          Cmd_transfer_end<=1'b0;
    end
 end
 // generation of a counter(0-63)
 always @( posedge clk_20M)
 begin
    if(clk_400K_en) begin
       if(start_transfer_cmd)
          Cmd_bit_counter<=Cmd_bit_counter+1'b1;
       else 
          Cmd_bit_counter<=48'b0;
    end
 end
 /*************************END****************************************************************************************/
 /***********************Response Receiving Logic*********************************************************************/
 reg Device_resp_temp;
 reg [135:0] Received_response;
 
 reg [7:0] Resp_bit_counter;
 
 always @( posedge clk_20M)
 begin
   if (rst) begin
      Device_resp_temp<=1'b1;
   end
   else if(clk_400K_en) begin
      if(start_receiving_resp) begin
           Device_resp_temp<=device_response_in;      //MARK          MARK    MARK 
          //Device_resp_temp<=Test_device_cmd;
      end
      else begin
         Device_resp_temp<=1'b1;
      end
   end
  end
  
 always @( posedge clk_20M)
 begin
   if (rst) begin
      Response_Arriving<=1'b0;
      Response_received<=1'b0;
   end
   else if(clk_400K_en) begin
     if(Device_resp_temp==1'b0) begin
       Response_Arriving<=1'b1;
       Response_received<=1'b0;
     end
     else begin
       if(Resp_bit_counter==Resp_length) begin// if Device_resp_temp==1'b1 && counter==47 / 135 , which meet the end bit of the response
          Response_received<=1'b1;
          Response_Arriving<=1'b0;
       end
       else begin
          Response_received<=1'b0;
          Response_Arriving<=Response_Arriving;
       end
     end
   end
 end
 
 always @( posedge clk_20M)
 begin
   if(clk_400K_en) begin
      if(Response_Arriving) begin
          Received_response<={Received_response[134:0],Device_resp_temp};
          Received_resp_buff<=Received_response;
          Resp_bit_counter<=Resp_bit_counter+1'b1;
      end
      else begin
          Received_response<=136'b0;
          Resp_bit_counter<='b0;
      end
        
   end
 end

 always @( posedge clk_20M)
 begin
     if(Start_check_resp) begin
        if(Received_resp_buff[39]==1'b0) begin // device is still busy, has not finished the power up routine
             Check_resp_passed<=2'b10;
        end
        else begin
         if(Received_resp_buff[38:37]==2'b10) // Device supports sector addressing 
             Check_resp_passed<=2'b11; 
         else 
             Check_resp_passed<=2'b01; // Device does not support sector addressing 
        end
     end
     else begin
        Check_resp_passed<=2'b00; // do nothing 
     end
     
 end 
 /*************************END****************************************************************************************/
 /*********************************Delay logic************************************************************************/
 always @( posedge clk_20M  )    
  begin
     if(rst) begin
         delay_counter<='h0;
     end
     else begin
       delay_counter <= delay_counter + 1'b1;
     end
   end
   assign Powerup_delay_end=delay_counter[12];
  
// Configrable delay timers (0-31 clock cycles) for backward compatibility mode operations 
 always@(posedge clk_20M)
 begin
     if( 1'b1==Timer1Start) begin
          if (1'b1==clk_400K_en) 
              Timer1<=Timer1+1'b1;
          else 
              Timer1<=Timer1;
     end
    else begin
            Timer1<='h00;
     end
  end
  
  // Configrable delay timers (0-31 clock cycles) for HS400 Enhanced Strobe mode operations
 always@(posedge clk_20M)
 begin
     if( 1'b1==Timer2Start) begin
          Timer2<=Timer2+1'b1;
     end
    else begin
          Timer2<='h00;
     end
  end
  
   always@(posedge clk_20M)
 begin
     if( 1'b1==HS400E_delay_counter_en) begin
          HS400E_delay_counter<=HS400E_delay_counter+1'b1;
     end
    else begin
          HS400E_delay_counter<='h00;
     end
  end
 /***********************************END******************************************************************************/

 CRC7_400K crc7_400K(
    .clk(clk_20M),
	.clk_en(clk_400K_en),
	.BITVAL(Cmd_info_bit),
	.Enable(CRC_en),
	.rst(CRC_rst),  
    .CRC(CRC_out)
    );
    
 CRC7 CRC7_HS400E(
      .clk(clk_200M),
      .BITVAL(HS400E_Cmd_info_bit),// Next input bit  
      .Enable(HS400E_CRC_en),                  
      .rst(HS400E_CRC_rst),                           // Init CRC value  
      .CRC(HS400E_CRC_out)                               // Current output CRC value
       );
	    
 
 ////////////////////////////////////////////////////////////////////
 //Instantiation of internal modules

 Command_fifo Finished_Cmd_fifo_inst0 (
      .clk(clk_200M),      // input wire clk
      .srst(rst),    // input wire srst
      .din(rd_cmd_temp),      // input wire [63 : 0] din
      .wr_en(Finished_cmd_wr_en),  // input wire wr_en
      .rd_en(finished_cmd_rd_en),  // input wire rd_en
      .dout(finished_cmd_out),    // output wire [63 : 0] dout
      .full(Finished_cmd_fifo_full),    // output wire full
      .empty(finished_cmd_empty)  // output wire empty
    );  

Read_data512B_buffer Read_buffer_inst0(
  .clk(clk_200M),      // input wire clk
  .srst(rst||turning_end_rst),    // input wire srst
  .din(Device_data_temp),      // input wire [15 : 0] din
  .wr_en(rd_buf_wr_en),  // input wire wr_en
  .rd_en(fifo_wr_en),  // input wire rd_en
  .dout(rd_data_fifo_out),    // output wire [15 : 0] dout
  .full(),    // output wire full
  .empty()  // output wire empty
);   

Data_fifo Read_buffer_final(
      .clk(clk_200M),      // input wire clk
      .srst(rst||turning_end_rst),    // input wire srst
      .din(rd_data_final),      // input wire [7 : 0] din
      .wr_en(fifo_wr_en),  // input wire wr_en
      .rd_en(rd_data_rd_en),  // input wire rd_en
      .dout(rd_data_out),    // output wire [7 : 0] dout
      .full(),    // output wire full
      .empty(rd_data_empty)  // output wire empty
    );

Data_fifo Wr_data_fifo_inst0 (
      .clk(clk_200M),      // input wire clk
      .srst(rst),    // input wire srst
      .din(data_in),      // input wire [7 : 0] din
      .wr_en(data_wr_en),  // input wire wr_en
      .rd_en(rd_data_fifo_en||(fifo_wr_en&&Operation_type[0])),  // input wire rd_en
      .dout(fifo_data_16),    // output wire [7 : 0] dout
      .full(data_fifo_full),    // output wire full
      .empty()  // output wire empty
    );
	
blk_mem_gen_0 write_buffer_inst0 (
  .clka(clk_200M),    // input wire clka
  .rsta(rst),    // input wire rsta
  .ena(write_buf_en),      // input wire ena
  .wea(rd_data_fifo_en),      // input wire [0 : 0] wea
  .addra(back_up_addr),  // input wire [7 : 0] addra
  .dina(fifo_data_16),    // input wire [15 : 0] dina
  .douta(back_up_out)  // output wire [15 : 0] douta
);
    /*
   Data_fifo rd_data_fifo_inst0 (
          .clk(clk_200M),      // input wire clk
          .srst(rst),    // input wire srst
          .din(),      // input wire [7 : 0] din
          .wr_en(),  // input wire wr_en
          .rd_en(rd_data_rd_en),  // input wire rd_en
          .dout(rd_data_out),    // output wire [7 : 0] dout
          .full(),    // output wire full
          .empty(rd_data_empty)  // output wire empty
        );
     */   
        
  /***************************** Just for simulation purpose*************************************
       localparam RESPONSE_CMD1='h 41c0ff808089 ;
       localparam RESPONSE_CMD2='h3f_0123456789abcdef0123456789abcdef;
       integer i;
       reg [7:0] EXT_CSD_4Sim;
       initial begin
       Test_device_EXT_CSD=8'hzz;
        EXT_CSD_4Sim='hff;
       // #178455;
         //#924905;
         #628186;
       #100;
           #100;
       #100;
       #100;
       #100;
       #100;
       #100;
   
        for( i=0; i<531; i=i+1)
        begin
           Test_device_EXT_CSD=EXT_CSD_4Sim;
           EXT_CSD_4Sim=EXT_CSD_4Sim+1'b1;
                #100;
        end
         Test_device_EXT_CSD=8'hzz;
       end
       
       /****************************END***************************************************************/ 
       
 `ifdef SIMULATION
initial
begin
Test_device_cmd=1'b1;
#740067.5;
Test_device_cmd=1'b0;
#50;
Test_device_cmd=1'b0;
#50;
Test_device_cmd=1'b1;
#50;
Test_device_cmd=1'b0;
#50;
Test_device_cmd=1'b1;
#50;
Test_device_cmd=1'b0;
#5000;
Test_device_cmd=1'b1;

end	
  `endif

 
`ifdef SIMULATION
initial
begin
#6300
Next_State = 5'h1d;
#1000
HS400E_en=1'b1;
#53000
HS400E_Cmd_transfer_end = 1'b1;
#20000
HS400E_crc16_status_end = 1'b1;
#1000
HS400E_Received_crc16_status=CRC_STATUS_RIGHT;
#30000
HS400E_Cmd_transfer_end = 1'b1;
#20000
HS400E_crc16_status_end = 1'b1;
#1000
HS400E_Received_crc16_status=CRC_STATUS_WRONG;

end	
  `endif
endmodule
