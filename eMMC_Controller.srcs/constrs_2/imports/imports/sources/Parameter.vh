/************************************Local parameters definition for Commands *************************************************************************************/
 // 48 bits command 
 // Start bit(0) + trasmission direction bit(1) + command index (1)+ Augument( OCR register(0x40FF 8080)) + CRC7( previous bits) +end bit(1)
 //localparam CMD1={ {8'b01_000_001},  {{1'b0},{2'b10},{5'b0},{9'b1_1111_1111},{7'b0},{1'b1},{7'b0}}, {7'h44}, {1'b1} }; // 0x4140ff808089

 //localparam  CMD0=48'h40_1234_5675;
 localparam  CMD0                =40'h40_0000_0000;   // Reset device to Idel state.
 localparam  CMD1                =40'h41_c0ff_8080;   // Validation of  whether the devices support sector addressing.
 localparam  CMD2                =40'h42_0000_0000;  // Request all the devices to send CID serially to host.
 //localparam  CMD3_RCA1           =40'h43_0001_0000;  // Set RCA of the responsed device 0x0001.
 //localparam  CMD3_RCA2           =40'h43_0002_0000; 
 //localparam  CMD3_RCA3           =40'h43_0003_0000;
 //localparam  CMD3_RCA4           =40'h43_0004_0000;
 localparam  CMD6_HS_MODE           =40'h46_03b9_0100; // Switch to High Speed mode, with setting the Timing field of HS_TIMING[185] 0x01;
 localparam  CMD6_HS200_MODE        =40'h46_03b9_0200; // Switch to HS200 mode, with setting the Timing field of HS_TIMING[185] 0x02;
 localparam  CMD6_HS400_MODE        =40'h46_03b9_0300; // Switch to HS400 mode, with setting the Timing field of HS_TIMING[185] 0x03;
 localparam  CMD6_BUS_WIDTH_X8      =40'h46_03b7_8600; // Set dual data rate x8 bus mode and enalble Enhanced Strobe. BUS_WIDTH[183] of Extended CSD=0x86.
  localparam  CMD8                  =40'h48_0000_0000;
 /*******************************************END*********************************************************************************************************/
 /*********************************State definition of State machine for HS400 Enhanced Strobe operations**********************************/
 localparam H_Waiting4_HS400E               = 5'h00;
 localparam H_Delay_100us_4Clk_up           = 5'h01;
 localparam H_Idel                          = 5'h02;
 localparam H_Fetch_cmd                     = 5'h03;
 localparam H_Extract_cmd                   = 5'h04;
 localparam H_Writing_data_512B             = 5'h05;
 localparam H_Reading_data_512B             = 5'h06;
 localparam H_Is_finished_cmd_fifo_full     = 5'h07;
 localparam H_finished_cmd                     = 5'h08;
 localparam H_Tuning_start                     = 5'h09;
 localparam H_Tuning_end                     = 5'h0a;
 /************************************************END****************************************************************************************************/
 /*******************************State definition of State machine for detailed steps of a specific operation********************************************/

 localparam Steps_delay_16cc             = 5'h00;
 localparam Steps_idle                   = 5'h01;
 /*
 localparam Steps_sending_CMD8           = 5'h02;
 localparam Steps_receiving_EXT_CSD      = 5'h03;
 localparam Steps_halt                   = 5'h04;
 */
 
 localparam Steps_sending_CMD7           = 5'h02;
 localparam Steps_receiving_resp_4CMD7   = 5'h03;
 localparam Steps_check_resp_4CMD7       = 5'h04;
 
 localparam Steps_sending_CMD24          = 5'h05;
 localparam Steps_receiving_resp_4CMD24  = 5'h06;
 localparam Steps_check_resp_4CMD24      = 5'h07;
 localparam Steps_sendingdata_512B       = 5'h08;
 localparam Steps_receiving_CRC_status   = 5'h09;
 localparam Steps_check_CRC_status       = 5'h0a;
 localparam Steps_write_right            = 5'h0b;
 
 localparam Steps_sending_CMD17          = 5'h0c;
 localparam Steps_receiving_data         = 5'h0d;
 localparam Steps_check_received_data    = 5'h0e;
 localparam Steps_data_right             = 5'h0f;
 localparam Steps_fifo_write             = 5'h10;
 localparam Steps_fifo_complete          = 5'h11;
 
 localparam Steps_halt                   = 5'h12;
 localparam Steps_write_wrong            = 5'h13; 
 
 localparam Steps_tuning_cmd_w            = 5'h14; 
 localparam Steps_tuning_cmd_r            = 5'h15; 
 localparam Steps_tap_inc                 = 5'h16;
 localparam Steps_tuning_right            = 5'h17;
 /********************************************END********************************************************************************************************/
 /*********************************State definition of State machine for legacy mode(Backfords compatibility) operation**********************************/
 localparam  Power_up_delay              = 5'h00;
 localparam  Reset_device                = 5'h01;
 localparam  Delay_16cycle_CMD0to1       = 5'h02;
 localparam Idle_State                   = 5'h03;
 localparam Receiving_resp_4CMD1         = 5'h04;
 localparam Check_response               = 5'h05;
 //Identification process          
 localparam Delay_16cycle_CMD2           = 5'h06;
 localparam Sending_CMD2                 = 5'h07;
 localparam Receiving_CID                = 5'h08;
 localparam Next_device                  = 5'h09;
 localparam Delay_16cycle_CMD3           = 5'h0a;
 localparam Sending_CMD3                 = 5'h0b;
 localparam Receiving_resp_4CMD3         = 5'h0c;
 localparam Check_Device_status          = 5'h0d;
 localparam Stand_by_state               = 5'h0e;
 // HS400 with Enhanced Strobe Selection
 localparam Delay_16cycle_CMD7           = 5'h0f;
 localparam Sending_CMD7                 = 5'h10;
 localparam Receiving_resp_4CMD7         = 5'h11;
 localparam Check_resp_4CMD7             = 5'h12;
 localparam Set_timing_HSmode            = 5'h13;
 localparam Receiving_resp_4CMD6_HS      = 5'h14;
 localparam Check_resp_4CMD6_HS          = 5'h15;
 localparam Set_bus_width_x8             = 5'h16;
 localparam Receiving_resp_4CMD6_BW      = 5'h17;
 localparam Check_resp_4CMD6_BW          = 5'h18;
 localparam Set_timing_HS400             = 5'h19;
 localparam Receiving_resp_4CMD6_HS400   = 5'h1a;                    
 localparam Check_resp_4CMD6_HS400       = 5'h1b;
 localparam Next_RCA_4_activation        = 5'h1c;
 localparam HS400_Ready                  = 5'h1d;                             
 
 localparam Error_state                  = 5'h1f; 
 /************************************************END*********************************************************************************************************/
 localparam CRC_STATUS_RIGHT=4'b0101;
 localparam CRC_STATUS_WRONG=4'b1011;