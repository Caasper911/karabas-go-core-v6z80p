`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Phil
// 
// Create Date:    15:28:23 04/28/2008 
// Design Name: 
// Module Name:    multiply 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module amiga_scaler(sample, volume, result);

	input signed [7:0] sample;
	input [6:0] volume;
	output [7:0] result;
	
   reg signed [15:0] QOUT;
   
always@(sample or volume)
 begin
    QOUT <= sample * volume;
 end

assign result[0] = QOUT [6];
assign result[1] = QOUT [7];
assign result[2] = QOUT [8];
assign result[3] = QOUT [9];
assign result[4] = QOUT [10];
assign result[5] = QOUT [11];
assign result[6] = QOUT [12];
assign result[7] = QOUT [13];

endmodule
