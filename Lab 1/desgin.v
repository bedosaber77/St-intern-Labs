module GP_gen #(parameter N = 16)(
  input [N-1:0] A,
  input [N-1:0] B,
  output [N-1:0] p,
  output [N-1:0] g
);
  genvar i;
  generate
    for (i = 0; i < N; i = i + 1) begin : gen_block
      assign p[i] = A[i] ^ B[i];  
      assign g[i] = A[i] & B[i]; 
    end
  endgenerate
endmodule

module sum #(parameter N = 16)(
    input [N-1:0] P,
    input [N-1:0] C,
    output [N-1:0] S
);
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_block
        assign S[i] = P[i] ^ C[i];  
        end
    endgenerate
endmodule

module carry_look_ahead_gen #(parameter N = 4)(
  input [N-1:0] p,
  input [N-1:0] g,
  input cin,
  output [N:1] c,
  output P,
  output G
);
  assign c[1] = g[0] | (p[0] & cin);
  assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
  assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
  assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | 
                                                               (p[3] & p[2] & p[1] & p[0] & cin);

  assign P = p[3] & p[2] & p[1] & p[0];
  assign G = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
endmodule

module sixteen_bit_cla_adder(
  input [15:0] A,
  input [15:0] B,
  input cin,
  output [15:0] S,
  output cout,
  output P,
  output G
);
  wire [15:0] p, g;
  wire [4:0] block_P, block_G;
  wire [16:1] carry;

  // Generate Propagate and Generate signals for each 4-bit block
  GP_gen #(.N(16)) gp_gen_inst (
    .A(A),
    .B(B),
    .p(p),
    .g(g)
  );

  // First level of CLA for 4-bit blocks
  carry_look_ahead_gen #(.N(4)) cla_0_3 (
    .p(p[3:0]),
    .g(g[3:0]),
    .cin(cin),
    .c(carry[4:1]),
    .P(block_P[0]),
    .G(block_G[0])
  );

  carry_look_ahead_gen #(.N(4)) cla_4_7 (
    .p(p[7:4]),
    .g(g[7:4]),
    .cin(carry[4]),
    .c(carry[8:5]),
    .P(block_P[1]),
    .G(block_G[1])
  );

  carry_look_ahead_gen #(.N(4)) cla_8_11 (
    .p(p[11:8]),
    .g(g[11:8]),
    .cin(carry[8]),
    .c(carry[12:9]),
    .P(block_P[2]),
    .G(block_G[2])
  );

  carry_look_ahead_gen #(.N(4)) cla_12_15 (
    .p(p[15:12]),
    .g(g[15:12]),
    .cin(carry[12]),
    .c(carry[16:13]),
    .P(block_P[3]),
    .G(block_G[3])
  );

  carry_look_ahead_gen #(.N(4)) cla_Level2 (
    .p(block_P[3:0]),
    .g(block_G[3:0]),
    .cin(cin),
    .c({carry[16],carry[12],carry[8],carry[4]}),
    .P(block_P[4]),
    .G(block_G[4])
  );
  // Sum generation for each block
  sum #(.N(4)) sum_0_3 (
    .P(p[3:0]),
    .C({carry[3:1], cin}),
    .S(S[3:0])
  );

  sum #(.N(4)) sum_4_7 (
    .P(p[7:4]),
    .C(carry[7:4]),
    .S(S[7:4])
  );

  sum #(.N(4)) sum_8_11 (
    .P(p[11:8]),
    .C(carry[11:8]),
    .S(S[11:8])
  );

  sum #(.N(4)) sum_12_15 (
    .P(p[15:12]),
    .C(carry[15:12]),
    .S(S[15:12])
  );
  assign cout = carry[16];
  assign P = block_P[4];
  assign G = block_G[4];
endmodule


module sixtyfour_bit_cla_adder
  (
    input [63:0] A,
    input [63:0] B,
    input cin,
    output [63:0] S,
    output cout
  );
  wire [15:0] S0, S1, S2, S3;
  wire cout0, cout1, cout2;
  wire [4:0] Local_P, Local_G;
  sixteen_bit_cla_adder sixteen_bit_cla_adder0(
    .A(A[15:0]),
    .B(B[15:0]),
    .cin(cin),
    .S(S0),
    .cout(),
    .P(Local_P[0]),
    .G(Local_G[0])
  );
  sixteen_bit_cla_adder sixteen_bit_cla_adder1(
    .A(A[31:16]),
    .B(B[31:16]),
    .cin(cout0),
    .S(S1),
    .cout(),
    .P(Local_P[1]),
    .G(Local_G[1])
  );
  sixteen_bit_cla_adder sixteen_bit_cla_adder2(
    .A(A[47:32]),
    .B(B[47:32]),
    .cin(cout1),
    .S(S2),
    .cout(),
    .P(Local_P[2]),
    .G(Local_G[2])
  );
  sixteen_bit_cla_adder sixteen_bit_cla_adder3(
    .A(A[63:48]),
    .B(B[63:48]),
    .cin(cout2),
    .S(S3),
    .cout(),
    .P(Local_P[3]),
    .G(Local_G[3])
  );
  carry_look_ahead_gen #(.N(4)) cla_Level2 (
    .p(Local_P[3:0]),
    .g(Local_G[3:0]),
    .cin(cin),
    .c({cout,cout2,cout1,cout0}),
    .P(Local_P[4]),
    .G(Local_G[4])
  );
  assign S = {S3, S2, S1, S0};

endmodule