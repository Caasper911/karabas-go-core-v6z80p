`timescale 1ns / 1ps

module xor8reg (
input reset_in,
input clock_in,
input [7:0] in_a,
output [7:0] out_b
);

reg [7:0] acc;

always @(posedge clock_in)

if (reset_in == 1'b1) begin
 acc[7:0] <= 8'h00;
 end
else begin
 acc[7:0] <= {acc[7:0]} ^ {in_a[7:0]};
 end

assign out_b = acc[7:0];

endmodule
