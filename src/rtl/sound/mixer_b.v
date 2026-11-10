`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:37:40 03/25/2011 
// Design Name: 
// Module Name:    mixer_b
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

module mixer_b(
    input clock_in,
    output carry_out,
    output [9:0] sum_out,      // Karabas Go port: the sum of the four channels itself (PCM, 512 = silence)
    input [7:0] chn_a,
    input [7:0] chn_b,
    input [7:0] chn_c,
    input [7:0] chn_d,
    input chn_a_en,
    input chn_b_en,
    input chn_c_en,
    input chn_d_en
    );

reg [10:0] pwm_acc;

always @(posedge clock_in)

pwm_acc[10:0] <= {1'b0,pwm_acc[9:0]} + {chn_a_en?chn_a:8'h80} + {chn_b_en?chn_b:8'h80} + {chn_c_en?chn_c:8'h80} + {chn_d_en?chn_d:8'h80};

assign carry_out = pwm_acc[10];

assign sum_out = {2'b00, chn_a_en ? chn_a : 8'h80} + {2'b00, chn_b_en ? chn_b : 8'h80} + {2'b00, chn_c_en ? chn_c : 8'h80} + {2'b00, chn_d_en ? chn_d : 8'h80};

endmodule

