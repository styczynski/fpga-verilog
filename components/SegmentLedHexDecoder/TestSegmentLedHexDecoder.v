`timescale 1ns / 1ps
`include "./SegmentLedHexDecoder.v"

`define assert(label, signal, value) \
        #1; \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m:"); \
            $display("  [%s] signal != value", label); \
            $finish; \
        end

/*
 * Piotr Styczyński @styczynski
 * Verilog Components Library
 *
 * Tests for 8-segment led hex decoder
 *
 * MIT License
 */
module TestSegmentLedHexDecoder;

    // Inputs
    reg [3:0] HexDigit;
    

	// Outputs
    wire SegmentA;
    wire SegmentB;
    wire SegmentC;
    wire SegmentD;
    wire SegmentE;
    wire SegmentF;
    wire SegmentG;

	// Instantiate the Unit Under Test (UUT)
	SegmentLedHexDecoder uut (
		.HexDigit(HexDigit),
        .Segments({
            SegmentG, SegmentF, SegmentE, SegmentD, SegmentC, SegmentB, SegmentA
        })
	);

	initial begin
		// Initialize Inputs
		
        #100;
        
        // Digit 0
        HexDigit = 0;
        #2;
        
        `assert("Digit 0", SegmentA, 0);
		`assert("Digit 0", SegmentB, 0);
        `assert("Digit 0", SegmentC, 0);
        `assert("Digit 0", SegmentD, 0);
        `assert("Digit 0", SegmentE, 0);
        `assert("Digit 0", SegmentF, 0);
        `assert("Digit 0", SegmentG, 1);
        
        // Digit 1
        HexDigit = 1;
        #2;
        
        `assert("Digit 1", SegmentA, 1);
		`assert("Digit 1", SegmentB, 0);
        `assert("Digit 1", SegmentC, 0);
        `assert("Digit 1", SegmentD, 1);
        `assert("Digit 1", SegmentE, 1);
        `assert("Digit 1", SegmentF, 1);
        `assert("Digit 1", SegmentG, 1);
        
        // Digit 2
        HexDigit = 2;
        #2;
        
        `assert("Digit 2", SegmentA, 0);
		`assert("Digit 2", SegmentB, 0);
        `assert("Digit 2", SegmentC, 1);
        `assert("Digit 2", SegmentD, 0);
        `assert("Digit 2", SegmentE, 0);
        `assert("Digit 2", SegmentF, 1);
        `assert("Digit 2", SegmentG, 0);
        
        // Digit 3
        HexDigit = 3;
        #2;
        
        `assert("Digit 3", SegmentA, 0);
		`assert("Digit 3", SegmentB, 0);
        `assert("Digit 3", SegmentC, 0);
        `assert("Digit 3", SegmentD, 0);
        `assert("Digit 3", SegmentE, 1);
        `assert("Digit 3", SegmentF, 1);
        `assert("Digit 3", SegmentG, 0);
        
        // Digit 4
        HexDigit = 4;
        #2;
        
        `assert("Digit 4", SegmentA, 1);
		`assert("Digit 4", SegmentB, 0);
        `assert("Digit 4", SegmentC, 0);
        `assert("Digit 4", SegmentD, 1);
        `assert("Digit 4", SegmentE, 1);
        `assert("Digit 4", SegmentF, 0);
        `assert("Digit 4", SegmentG, 0);
        
        // Digit 5
        HexDigit = 5;
        #2;
        
        `assert("Digit 5", SegmentA, 0);
		`assert("Digit 5", SegmentB, 1);
        `assert("Digit 5", SegmentC, 0);
        `assert("Digit 5", SegmentD, 0);
        `assert("Digit 5", SegmentE, 1);
        `assert("Digit 5", SegmentF, 0);
        `assert("Digit 5", SegmentG, 0);
        
        // Digit 6
        HexDigit = 6;
        #2;
        
        `assert("Digit 6", SegmentA, 0);
		`assert("Digit 6", SegmentB, 1);
        `assert("Digit 6", SegmentC, 0);
        `assert("Digit 6", SegmentD, 0);
        `assert("Digit 6", SegmentE, 0);
        `assert("Digit 6", SegmentF, 0);
        `assert("Digit 6", SegmentG, 0);
        
        // Digit 7
        HexDigit = 7;
        #2;
        
        `assert("Digit 7", SegmentA, 0);
		`assert("Digit 7", SegmentB, 0);
        `assert("Digit 7", SegmentC, 0);
        `assert("Digit 7", SegmentD, 1);
        `assert("Digit 7", SegmentE, 1);
        `assert("Digit 7", SegmentF, 1);
        `assert("Digit 7", SegmentG, 1);
        
        // Digit 8
        HexDigit = 8;
        #2;
        
        `assert("Digit 8", SegmentA, 0);
		`assert("Digit 8", SegmentB, 0);
        `assert("Digit 8", SegmentC, 0);
        `assert("Digit 8", SegmentD, 0);
        `assert("Digit 8", SegmentE, 0);
        `assert("Digit 8", SegmentF, 0);
        `assert("Digit 8", SegmentG, 0);
        
        // Digit 9
        HexDigit = 9;
        #2;
        
        `assert("Digit 9", SegmentA, 0);
		`assert("Digit 9", SegmentB, 0);
        `assert("Digit 9", SegmentC, 0);
        `assert("Digit 9", SegmentD, 0);
        `assert("Digit 9", SegmentE, 1);
        `assert("Digit 9", SegmentF, 0);
        `assert("Digit 9", SegmentG, 0);
        
        // Digit A
        HexDigit = 10;
        #2;
        
        `assert("Digit A", SegmentA, 0);
		`assert("Digit A", SegmentB, 0);
        `assert("Digit A", SegmentC, 0);
        `assert("Digit A", SegmentD, 1);
        `assert("Digit A", SegmentE, 0);
        `assert("Digit A", SegmentF, 0);
        `assert("Digit A", SegmentG, 0);
        
        // Digit B
        HexDigit = 11;
        #2;
        
        `assert("Digit B", SegmentA, 1);
		`assert("Digit B", SegmentB, 1);
        `assert("Digit B", SegmentC, 0);
        `assert("Digit B", SegmentD, 0);
        `assert("Digit B", SegmentE, 0);
        `assert("Digit B", SegmentF, 0);
        `assert("Digit B", SegmentG, 0);
        
        // Digit C
        HexDigit = 12;
        #2;
        
        `assert("Digit C", SegmentA, 0);
		`assert("Digit C", SegmentB, 1);
        `assert("Digit C", SegmentC, 1);
        `assert("Digit C", SegmentD, 0);
        `assert("Digit C", SegmentE, 0);
        `assert("Digit C", SegmentF, 0);
        `assert("Digit C", SegmentG, 1);
        
        // Digit D
        HexDigit = 13;
        #2;
        
        `assert("Digit D", SegmentA, 1);
		`assert("Digit D", SegmentB, 0);
        `assert("Digit D", SegmentC, 0);
        `assert("Digit D", SegmentD, 0);
        `assert("Digit D", SegmentE, 0);
        `assert("Digit D", SegmentF, 1);
        `assert("Digit D", SegmentG, 0);
        
        // Digit E
        HexDigit = 14;
        #2;
        
        `assert("Digit E", SegmentA, 0);
		`assert("Digit E", SegmentB, 1);
        `assert("Digit E", SegmentC, 1);
        `assert("Digit E", SegmentD, 0);
        `assert("Digit E", SegmentE, 0);
        `assert("Digit E", SegmentF, 0);
        `assert("Digit E", SegmentG, 0);
        
        // Digit F
        HexDigit = 15;
        #2;
        
        `assert("Digit F", SegmentA, 0);
		`assert("Digit F", SegmentB, 1);
        `assert("Digit F", SegmentC, 1);
        `assert("Digit F", SegmentD, 1);
        `assert("Digit F", SegmentE, 0);
        `assert("Digit F", SegmentF, 0);
        `assert("Digit F", SegmentG, 0);
        
        
        $finish;
	end
      
endmodule

