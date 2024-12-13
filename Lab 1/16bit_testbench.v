`timescale 1ns / 1ps
module tb_sixteen_bit_cla_adder;

// Inputs
reg [15:0] A;
reg [15:0] B;
reg cin;

// Outputs
wire [15:0] S;
wire cout;

// Instantiate the Unit Under Test (UUT)
sixteen_bit_cla_adder uut (
    .A(A),
    .B(B),
    .cin(cin),
    .S(S),
    .cout(cout)
);

initial begin
    // Initialize Inputs
    A = 16'b0;
    B = 16'b0;
    cin = 0;

    // Test Case 1: Basic Addition
    #10 A = 16'b0000000000000001; 
        B = 16'b0000000000000001; 
        cin = 0; 
        // Expected: S = 2, cout = 0

    // Test Case 2: Carry-Out Generation
    #10 A = 16'hFFFF; 
        B = 16'h0001; 
        cin = 0; 
        // Expected: S = 0, cout = 1

    // Test Case 3: Alternating Bits
    #10 A = 16'hAAAA; 
        B = 16'h5555; 
        cin = 0; 
        // Expected: S = FFFF, cout = 0

    // Test Case 4: Large Numbers with Carry-In
    #10 A = 16'h1234; 
        B = 16'hFEDC; 
        cin = 1; 
        // Expected: S = 1111, cout = 1

    // Test Case 5: Both Inputs Zero with Carry-In
    #10 A = 16'h0000; 
        B = 16'h0000; 
        cin = 1; 
        // Expected: S = 1, cout = 0

    // Test Case 6: Highest Bit Carry-Out
    #10 A = 16'h8000; 
        B = 16'h8000; 
        cin = 0; 
        // Expected: S = 0, cout = 1

    // Test Case 7: Half and Half Values
    #10 A = 16'h00FF; 
        B = 16'hFF00; 
        cin = 0; 
        // Expected: S = FFFF, cout = 0

    // Test Case 8: Overflow in Middle Bits
    #10 A = 16'h0FFF; 
        B = 16'h0001; 
        cin = 0; 
        // Expected: S = 1000, cout = 0

    // Test Case 9: Random Inputs with Carry-In
    #10 A = 16'h3A5C; 
        B = 16'hC4B2; 
        cin = 1; 
        // Expected: S = FEEE, cout = 0

    // Test Case 10: Maximum Values with Carry-In
    #10 A = 16'hFFFF; 
        B = 16'hFFFF; 
        cin = 1; 
        // Expected: S = FFFF, cout = 1

    // Test Case 11: Input A All Zeroes
    #10 A = 16'h0000; 
        B = 16'hABCD; 
        cin = 1; 
        // Expected: S = ABCE, cout = 0

    // Test Case 12: Input B All Zeroes
    #10 A = 16'hABCD; 
        B = 16'h0000; 
        cin = 0; 
        // Expected: S = ABCD, cout = 0

    // Test Case 13: Edge Case with Negative Numbers (Two's Complement)
    #10 A = 16'b1111111111111111; 
        B = 16'b1111111111111111; 
        cin = 1; 
        // Expected: S = FFFF, cout = 1

    // Test Case 14: Alternating Bits with Carry-In
    #10 A = 16'h5555; 
        B = 16'h5555; 
        cin = 1; 
        // Expected: S = AAAA, cout = 0

    // Test Case 15: Low Range Numbers
    #10 A = 16'h0002; 
        B = 16'h0003; 
        cin = 0; 
        // Expected: S = 0005, cout = 0

    #10 $stop; // Stop the simulation
end


initial begin
    $monitor("At time %t, A = %h, B = %h, cin = %b, S = %h, cout = %b",
             $time, A, B, cin, S, cout);
end

endmodule
