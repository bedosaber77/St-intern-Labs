// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps
module tb_sixty_four_bit_cla_adder;

// Inputs
reg [63:0] A;
reg [63:0] B;
reg cin;

// Outputs
wire [63:0] S;
wire cout;

// Instantiate the Unit Under Test (UUT)
sixtyfour_bit_cla_adder uut (
    .A(A),
    .B(B),
    .cin(cin),
    .S(S),
    .cout(cout)
);

initial begin
    // Initialize Inputs
    A = 64'b0;
    B = 64'b0;
    cin = 0;

    // Apply test vectors
    #10 A = 64'b0000000000000000000000000000000000000000000000000000000000000001; 
        B = 64'b0000000000000000000000000000000000000000000000000000000000000001; 
        cin = 0; 
        // Expected: S = 2, cout = 0

    #10 A = 64'hFFFFFFFFFFFFFFFF; 
        B = 64'h0000000000000001; 
        cin = 0; 
        // Expected: S = 0, cout = 1

    #10 A = 64'hAAAAAAAAAAAAAAAA; 
        B = 64'h5555555555555555; 
        cin = 0; 
        // Expected: S = FFFFFFFFFFFFFFFF, cout = 0

    #10 A = 64'h1234567890ABCDEF; 
        B = 64'hFEDCBA0987654321; 
        cin = 1; 
        // Expected: S = 11111111111111111, cout = 1

    #10 A = 64'h0000000000000000; 
        B = 64'h0000000000000000; 
        cin = 1; 
        // Expected: S = 1, cout = 0

    #10 A = 64'h8000000000000000; 
        B = 64'h8000000000000000; 
        cin = 0; 
        // Expected: S = 0, cout = 1

    // Add more test cases if needed
    #10 $stop; // Stop the simulation
end

initial begin
    $monitor("At time %t, A = %h, B = %h, cin = %b, S = %h, cout = %b",
             $time, A, B, cin, S, cout);
end

endmodule