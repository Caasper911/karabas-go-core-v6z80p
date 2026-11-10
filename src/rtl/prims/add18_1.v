`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Phil
// Create Date:    15:28:23 06/06/2008 
// Module Name:    add 18+1
//////////////////////////////////////////////////////////////////////////////////
module add_18_1(in_a, in_b, out_c);

	input [17:0] in_a;
	input in_b;
	output [17:0] out_c;
	
   reg [17:0] out_c;
   
always@(in_a or in_b)
 begin
    out_c <= in_a + in_b;
 end

endmodule
