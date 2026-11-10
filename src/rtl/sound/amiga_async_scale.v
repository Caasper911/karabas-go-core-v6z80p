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
    // Karabas Go port: was "sample * volume" - with the unsigned volume the whole product is unsigned (Verilog), a negative sample was taken
    // as 128..255 and the result came out 4*volume too high (mod 256): every negative half-wave was wrong below volume 64 (at 32 its sign flipped).
    QOUT <= sample * $signed({1'b0, volume});
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
