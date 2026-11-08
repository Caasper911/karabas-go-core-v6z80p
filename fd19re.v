// generated from fd19re.sch
module fd19re (
    input wire R,
    input wire CE,
    input wire C,
    output wire [18:0] Q,
    input wire [18:0] D
);

    wire XLXN_1;
    wire XLXN_2;
    wire XLXN_4;
    wire XLXN_6;
    wire XLXN_7;
    wire XLXN_8;

    fdre I_Q5 (.C(C), .CE(CE), .D(D[5]), .R(R), .Q(Q[5]));
    fdre I_Q6 (.C(C), .CE(CE), .D(D[6]), .R(R), .Q(Q[6]));
    fdre I_Q14 (.C(C), .CE(CE), .D(D[14]), .R(R), .Q(Q[14]));
    fdre I_Q13 (.C(C), .CE(CE), .D(D[13]), .R(R), .Q(Q[13]));
    fdre I_Q12 (.C(C), .CE(CE), .D(D[12]), .R(R), .Q(Q[12]));
    fdre I_Q11 (.C(C), .CE(CE), .D(D[11]), .R(R), .Q(Q[11]));
    fdre I_Q10 (.C(C), .CE(CE), .D(D[10]), .R(R), .Q(Q[10]));
    fdre I_Q9 (.C(C), .CE(CE), .D(D[9]), .R(R), .Q(Q[9]));
    fdre I_Q8 (.C(C), .CE(CE), .D(D[8]), .R(R), .Q(Q[8]));
    fdre I_Q7 (.C(C), .CE(CE), .D(D[7]), .R(R), .Q(Q[7]));
    fdre I_Q4 (.C(C), .CE(CE), .D(D[4]), .R(R), .Q(Q[4]));
    fdre I_Q3 (.C(C), .CE(CE), .D(D[3]), .R(R), .Q(Q[3]));
    fdre I_Q2 (.C(C), .CE(CE), .D(D[2]), .R(R), .Q(Q[2]));
    fdre I_Q1 (.C(C), .CE(CE), .D(D[1]), .R(R), .Q(Q[1]));
    fdre I_Q0 (.C(C), .CE(CE), .D(D[0]), .R(R), .Q(Q[0]));
    fdre I_Q15 (.C(C), .CE(CE), .D(D[15]), .R(R), .Q(Q[15]));
    fdre XLXI_1 (.C(C), .CE(CE), .D(D[16]), .R(R), .Q(Q[16]));
    fdre XLXI_2 (.C(C), .CE(CE), .D(D[17]), .R(R), .Q(Q[17]));
    fdre XLXI_3 (.C(C), .CE(CE), .D(D[18]), .R(R), .Q(Q[18]));

endmodule
