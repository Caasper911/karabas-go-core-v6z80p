`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Phil
// Create Date:    15:28:23 06/06/2008 
// Module Name:    sub 16_1
//////////////////////////////////////////////////////////////////////////////////
module sub_16_1(in_a, in_b, out_c);

	input [15:0] in_a;
	input in_b;
	output [15:0] out_c;
	
   reg [15:0] out_c;
   
always@(in_a or in_b)
 begin
    out_c <= in_a - in_b;
 end

endmodule
