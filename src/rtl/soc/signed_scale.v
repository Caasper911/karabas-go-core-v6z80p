`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Phil
// Create Date:    15:28:23 06/06/2008 
// Module Name:    signed multiply / scale
//////////////////////////////////////////////////////////////////////////////////
module signed_scale(multiplier, multiplicand, product);

	input signed [15:0] multiplier;
	input signed [15:0] multiplicand;
	output [15:0] product;
	
   reg signed [29:0] QOUT;
   
always@(multiplier or multiplicand)
 begin
    QOUT <= multiplier * multiplicand;
 end

assign product[0] = QOUT [14];
assign product[1] = QOUT [15];
assign product[2] = QOUT [16];
assign product[3] = QOUT [17];
assign product[4] = QOUT [18];
assign product[5] = QOUT [19];
assign product[6] = QOUT [20];
assign product[7] = QOUT [21];
assign product[8] = QOUT [22];
assign product[9] = QOUT [23];
assign product[10] = QOUT [24];
assign product[11] = QOUT [25];
assign product[12] = QOUT [26];
assign product[13] = QOUT [27];
assign product[14] = QOUT [28];
assign product[15] = QOUT [29];

endmodule
