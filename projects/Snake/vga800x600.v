`timescale 1ns / 1ps
`ifndef LIB_STYCZYNSKI_VGA_800X600_V
`define LIB_STYCZYNSKI_VGA_800X600_V

`include "../../components/DualPortRam/DualPortRam.v"

module vga800x600(
    input wire i_clk,           // base clock
    input wire i_pix_stb,       // pixel clock strobe
    output reg VgaColorR,
    output reg VgaColorG,
    output reg VgaColorB,
    input wire i_rst,           // reset: restarts frame
    output wire o_hs,           // horizontal sync
    output wire o_vs,           // vertical sync
    output wire o_blanking,     // high during blanking interval
    output wire o_active,       // high during active pixel drawing
    output wire o_screenend,    // high for one tick at the end of screen
    output wire o_animate,      // high for one tick at end of active drawing
    output wire [10:0] o_x,     // current pixel x position
    output wire  [9:0] o_y,      // current pixel y position
    input wire FrameBufferWrite,
    input wire [16:0] FrameBufferAddr,
    input wire [2:0] FrameBufferInput,
    output wire [2:0] FrameBufferOutput
    );

    
    // VGA timings https://timetoexplore.net/blog/video-timings-vga-720p-1080p
    localparam HS_STA = 40;              // horizontal sync start
    localparam HS_END = 40 + 128;        // horizontal sync end
    localparam HA_STA = 40 + 128 + 88;   // horizontal active pixel start
    localparam VS_STA = 600 + 1;         // vertical sync start
    localparam VS_END = 600 + 1 + 4;     // vertical sync end
    localparam VA_END = 600;             // vertical active pixel end
    localparam LINE   = 1056;            // complete line (pixels)
    localparam SCREEN = 628;             // complete screen (lines)

    wire [3:0] FrameBufferVgaOutput;
    
    DualPortRam #(
        .DATA_WIDTH(3),
        .ADDR_WIDTH(17)
    ) ram (
        .Clk(i_clk),
        .WriteA(FrameBufferWrite),
        .AddrA(FrameBufferAddr),
        .InputA(FrameBufferInput),
        .OutputA(FrameBufferOutput),
        .WriteB(0),
        .AddrB(CurrentPixelPtr[16:0]),
        .InputB(0),
        .OutputB(FrameBufferVgaOutput)
    );
    
    reg [20:0] CurrentPixelPtr;
    reg [20:0] LineStartPixelPtr;
    reg [20:0] LineRepeatCount;
    reg [20:0] PixelRepeatCount;
    
    reg [10:0] h_count; // line position
    reg [9:0] v_count; // screen position
    
    // generate sync signals (active high for 800x600)
    assign o_hs = ((h_count >= HS_STA) & (h_count < HS_END));
    assign o_vs = ((v_count >= VS_STA) & (v_count < VS_END));

    // keep x and y bound within the active pixels
    assign o_x = (h_count < HA_STA) ? 0 : (h_count - HA_STA);
    assign o_y = (v_count >= VA_END) ? (VA_END - 1) : (v_count);

    // blanking: high within the blanking period
    assign o_blanking = ((h_count < HA_STA) | (v_count > VA_END - 1));

    // active: high during active pixel drawing
    assign o_active = ~((h_count < HA_STA) | (v_count > VA_END - 1)); 

    // screenend: high for one tick at the end of the screen
    assign o_screenend = ((v_count == SCREEN - 1) & (h_count == LINE));

    // animate: high for one tick at the end of the final active pixel line
    assign o_animate = ((v_count == VA_END - 1) & (h_count == LINE));
    
    always @(posedge i_clk)
    begin
        if(i_rst)  // reset to start of frame
            begin
                h_count <= 0;
                v_count <= 0;
                CurrentPixelPtr <= 0;
                LineRepeatCount <= 0;
                PixelRepeatCount <= 0;
                LineStartPixelPtr <= 0;
            end
        else if(i_pix_stb)  // once per pixel
            begin
                if(h_count >= HA_STA && h_count < LINE)
                    begin
                        { VgaColorR, VgaColorG, VgaColorB } <= FrameBufferVgaOutput;
                        if(PixelRepeatCount < 1)
                            begin
                                PixelRepeatCount <= PixelRepeatCount + 1;
                            end
                        else
                            begin
                                CurrentPixelPtr <= CurrentPixelPtr+1;
                                PixelRepeatCount <= 0;
                            end
                    end
                if(h_count == LINE)
                    begin
                        if(LineRepeatCount < 1)
                            begin
                                LineRepeatCount <= LineRepeatCount + 1;
                                CurrentPixelPtr <= LineStartPixelPtr;
                                PixelRepeatCount <= 0;
                            end
                        else
                            begin
                                LineRepeatCount <= 0;
                                LineStartPixelPtr <= CurrentPixelPtr;
                                PixelRepeatCount <= 0;
                            end
                    end
                if(h_count == LINE)  // end of line
                    begin
                        h_count <= 0;
                        v_count <= v_count + 1;
                    end
                else
                    begin
                        h_count <= h_count + 1;
                    end

                if(v_count == SCREEN)  // end of screen
                    begin
                        v_count <= 0;
                        LineRepeatCount <= 0;
                        LineStartPixelPtr <= 0;
                        PixelRepeatCount <= 0;
                    end
            end
    end
endmodule

`endif