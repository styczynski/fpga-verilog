`timescale 1ns / 1ps
`include "../../utils/test.v"
`include "./SegmentLedHexDecoder.v"
`include "../SegmentLedHexEncoder/SegmentLedHexEncoder.v"

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
    reg [3:0] HexDigitOutput;

	// Instantiate the Unit Under Test (UUT)
	SegmentLedHexDecoder uut (
		.HexDigit(HexDigit),
        .Segments({
            SegmentG, SegmentF, SegmentE, SegmentD, SegmentC, SegmentB, SegmentA
        })
	);
    
    // Encoder for led digit -> hex transformation
    SegmentLedHexEncoder encoder (
        .HexDigit(HexDigitOutput),
        .Segments({
            SegmentG, SegmentF, SegmentE, SegmentD, SegmentC, SegmentB, SegmentA
        })
    );

	`startTest("SegmentLedHexDecoder")
		// Initialize Inputs
        #100;
        
        `describe("Render digit 0");
            HexDigit = 0; #2;
            `assert(HexDigitOutput, HexDigit);
        
        `describe("Render digit 1");
            HexDigit = 1; #2;
            `assert(HexDigitOutput, HexDigit);
        
        `describe("Render digit 1");
            HexDigit = 2; #2;
            `assert(HexDigitOutput, HexDigit);
        
        `describe("Render digit 3");
            HexDigit = 3; #2;
            `assert(HexDigitOutput, HexDigit);
        
        `describe("Render digit 4");
            HexDigit = 4; #2;
            `assert(HexDigitOutput, HexDigit);
        
        `describe("Render digit 5");
            HexDigit = 5; #2;
            `assert(HexDigitOutput, HexDigit);
        
        `describe("Render digit 6");
            HexDigit = 6; #2;
            `assert(HexDigitOutput, HexDigit);
            
        `describe("Render digit 7");
            HexDigit = 7; #2;
            `assert(HexDigitOutput, HexDigit);
        
        `describe("Render digit 8");
            HexDigit = 8; #2;
            `assert(HexDigitOutput, HexDigit);
        
        `describe("Render digit 9");
            HexDigit = 9; #2;
            `assert(HexDigitOutput, HexDigit);
        
        
    `endTest
      
endmodule

