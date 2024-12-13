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

 module sixteen_bit_carry_look_ahead_gen (
  input [15:0] Pin,
  input [15:0] Gin,
  input cin,
  output [16:0] cout,
  output Pout,
  output Gout
);
  assign cout[0] = cin;
  wire [4:0] block_P;
  wire [4:0] block_G;
  wire [3:0] carry;

  // First level of CLA for 4-bit blocks
  carry_look_ahead_gen #(.N(4)) cla_0_3 (
    .p(Pin[3:0]),
    .g(Gin[3:0]),
    .cin(cin),
    .c(cout[3:1]),
    .P(block_P[0]),
    .G(block_G[0])
  );

  carry_look_ahead_gen #(.N(4)) cla_4_7 (
    .p(Pin[7:4]),
    .g(Gin[7:4]),
    .cin(carry[0]),
    .c(cout[7:5]),
    .P(block_P[1]),
    .G(block_G[1])
  );

  carry_look_ahead_gen #(.N(4)) cla_8_11 (
    .p(Pin[11:8]),
    .g(Gin[11:8]),
    .cin(carry[1]),
    .c(cout[11:9]),
    .P(block_P[2]),
    .G(block_G[2])
  );

  carry_look_ahead_gen #(.N(4)) cla_12_15 (
    .p(Pin[15:12]),
    .g(Gin[15:12]),
    .cin(carry[2]),
    .c(cout[15:13]),
    .P(block_P[3]),
    .G(block_G[3])
  );

  carry_look_ahead_gen #(.N(4)) cla_Level2 (
    .p({block_P[3], block_P[2], block_P[1], block_P[0]}),
    .g({block_G[3], block_G[2], block_G[1], block_G[0]}),
    .cin(cin),
    .c(carry),
    .P(block_P[4]),
    .G(block_G[4])
  );

  assign cout[16] = carry[3];
  assign cout[12] = carry[2];
  assign cout[8] = carry[1];
  assign cout[4] = carry[0];
  assign Pout = block_P[4];
  assign Gout = block_G[4];
endmodule



module sixteen_bit_cla_adder  (
  input [15:0] A,
  input [15:0] B,
  input cin,
  output [15:0] S,
  output cout
);
  wire [15:0] p; // Propagate signals
  wire [15:0] g; // Generate signals
  wire [16:0] carry_out; // Internal carry-out wires

  // Generate propagate and generate signals
  GP_gen #(.N(16)) gp_gen (
    .A(A),
    .B(B),
    .p(p),
    .g(g)
  );

  // Carry look-ahead generator
  sixteen_bit_carry_look_ahead_gen cla_gen (
    .Pin(p),
    .Gin(g),
    .cin(cin),
    .cout(carry_out),
    .Pout(), // Remove if unused
    .Gout()  // Remove if unused
  );

  // Generate the sum
  sum #(.N(16)) sum_gen (
    .P(p),
    .C(carry_out[15:0]), // Use the first 16 carry-out bits
    .S(S)
  );

  // Assign final carry-out
  assign cout = carry_out[16];

endmodule


module sixtyfour_bit_cla_adder (
  input [63:0] A,
  input [63:0] B,
  input cin,
  output [63:0] S,
  output cout,
  output Pout,
  output Gout
);
  wire [63:0] p; // Propagate signals
  wire [63:0] g; // Generate signals
  wire [64:0] c_out; // Carry signals for all bits
  wire [3:0] carry; // Carry signals for blocks
  wire [3:0] Local_P; // Propagate signals for blocks
  wire [3:0] Local_G; // Generate signals for blocks

  // Generate propagate and generate signals
  GP_gen #(.N(64)) gp_gen (
    .A(A),
    .B(B),
    .p(p),
    .g(g)
  );
  // 16-bit CLA blocks
  sixteen_bit_carry_look_ahead_gen cla_gen_0 (
    .Pin(p[15:0]),
    .Gin(g[15:0]),
    .cin(cin),
    .cout(c_out[15:0]),
    .Pout(Local_P[0]),
    .Gout(Local_G[0])
  );

  sixteen_bit_carry_look_ahead_gen cla_gen_1 (
    .Pin(p[31:16]),
    .Gin(g[31:16]),
    .cin(carry[0]),
    .cout(c_out[31:16]),
    .Pout(Local_P[1]),
    .Gout(Local_G[1])
  );

  sixteen_bit_carry_look_ahead_gen cla_gen_2 (
    .Pin(p[47:32]),
    .Gin(g[47:32]),
    .cin(carry[1]),
    .cout(c_out[47:32]),
    .Pout(Local_P[2]),
    .Gout(Local_G[2])
  );

  sixteen_bit_carry_look_ahead_gen cla_gen_3 (
    .Pin(p[63:48]),
    .Gin(g[63:48]),
    .cin(carry[2]),
    .cout(c_out[63:48]),
    .Pout(Local_P[3]),
    .Gout(Local_G[3])
  );

  // Final block-level carry look-ahead
  carry_look_ahead_gen #(.N(4)) cla_gen_4 (
    .p(Local_P),
    .g(Local_G),
    .cin(cin),
    .c(carry),
    .P(Pout),
    .G(Gout)
  );

  // Generate the sum
  sum #(.N(64)) sum_gen (
    .P(p),
    .C(c_out[63:0]), // Carry-in for each bit
    .S(S)
  );

  // Assign final carry-out
  assign cout = c_out[64];
  assign c_out[16] = carry[0];
  assign c_out[32] = carry[1];
  assign c_out[48] = carry[2];
  assign c_out[64] = carry[3];

endmodule