`default_nettype none

/*
Scrolling procedural background using several LFSRs.
*/
module parallax(
    // CARAVEL
`ifdef USE_POWER_PINS
    inout vdda1,  // User area 1 3.3V supply
    inout vdda2,  // User area 2 3.3V supply
    inout vssa1,  // User area 1 analog ground
    inout vssa2,  // User area 2 analog ground
    inout vccd1,  // User area 1 1.8V supply
    inout vccd2,  // User area 2 1.8v supply
    inout vssd1,  // User area 1 digital ground
    inout vssd2,  // User area 2 digital ground
`endif

    input clk,
    inout reset,
    output hsync,
    output vsync,
    output [2:0] rgb
);
  wire display_on;
  wire [9:0] hpos;
  wire [9:0] vpos;
  reg [15:0] lfsr;
  reg [14:0] lfsr2;
  reg [13:0] lfsr3;
  reg [7:0] lfsr_, lfsr__;
  reg [6:0] lfsr_2, lfsr__2;
  reg [9:0] mount, mount_;
  reg [9:0] mount2, mount2_;
  reg [4:0] frame;

  VgaSyncGen vga(
    .px_clk(clk),
    .reset(reset),
    .hsync(hsync),
    .vsync(vsync),
    .x_px(hpos),
    .y_px(vpos),
    .activevideo(display_on)
  );

  // enable LFSR only in 256x256 area
  wire star_enable =  !hpos[8] & !vpos[8] & !hpos[9] & !vpos[9];
  wire star2_enable = star_enable & !hpos[0];
  wire star3_enable = star_enable & !hpos[0] & !hpos[1];

  // LFSR with period = 2^16-1 = 256*256-1
  //LFSR #(16'b1000000001011,0) lfsr_gen(
/*
  LFSR #(16'b1000000001011,0) lfsr_gen(
    .clk(clk),
    .reset(reset),
    .enable(star_enable),
    .lfsr(lfsr));

  LFSR #(15'b00000000011,0) lfsr_gen2(
    .clk(clk),
    .reset(reset),
    .enable(star2_enable),
    .lfsr(lfsr2));

  LFSR #(14'b0000000011,0) lfsr_gen3(
    .clk(clk),
    .reset(reset),
    .enable(star3_enable),
    .lfsr(lfsr3));
*/


  always @(posedge clk)
    begin
      if (hpos == 0 && vpos == 0) begin
        frame <= frame + 1;
      end

      if (star_enable)
        lfsr <= {1'b0, lfsr[15:1]} ^ (lfsr[0] ? 16'b1101000000001000 : 16'b0);
      if (star2_enable)
        lfsr2 <= {1'b0, lfsr2[14:1]} ^ (lfsr2[0] ? 15'b110000000000000 : 15'b0);
      if (star3_enable)
        lfsr3 <= {1'b0, lfsr3[13:1]} ^ (lfsr3[0] ? 14'b11100000000010 : 14'b0);

      if (hpos < 6 && vpos == 1) begin
        lfsr__ <= {1'b0, lfsr__[7:1]} ^ (lfsr__[0] ? 8'b10111000 : 8'b0);
        mount_ <= lfsr__[0] ? mount_ + 1: mount_ - 1;
      end
      else if (hpos == 0) begin
        lfsr_ <= lfsr__;
        mount <= mount_;
      end
      else if (star_enable) begin
        lfsr_ <= {1'b0, lfsr_[7:1]} ^ (lfsr_[0] ? 8'b10111000 : 8'b0);
        mount <= lfsr_[0] ? mount + 1: mount - 1;
      end

      if (hpos < 3 && vpos == 1) begin
        if (hpos[0] == frame[0])
          lfsr__2 <= {1'b0, lfsr__2[6:1]} ^ (lfsr__2[0] ? 7'b1100000 : 7'b0);
        mount2_ <= lfsr__2[0] ? mount2_ + 1: mount2_ - 1;
      end
      else if (hpos == 0) begin
        lfsr_2 <= lfsr__2;
        mount2 <= mount2_;
      end
      else if (star_enable) begin
        if (hpos[0] == frame[0])
          lfsr_2 <= {1'b0, lfsr_2[6:1]} ^ (lfsr_2[0] ? 7'b1100000 : 7'b0);
        mount2 <= lfsr_2[0] ? mount2 + 1: mount2 - 1;
      end



      if (reset) frame <= 0;
      if (reset) lfsr <=  16'b1100010001010111;
      if (reset) lfsr2 <= 15'b110001000110111;
      if (reset) lfsr3 <= 14'b11000100110111;
      if (reset) lfsr__ <= 8'b1100000;
      if (reset) lfsr_ <= 8'b1100000;
      if (reset) lfsr__2 <= 7'b110000;
      if (reset) lfsr_2 <= 7'b110000;
      if (reset) mount_ <= 200;//6'b110000;
      if (reset) mount <=  200;//6'b110000;
      if (reset) mount2_ <= 180;//6'b110000;
      if (reset) mount2 <=  180;//6'b110000;
    end


  assign rgb =
    (star_enable && (&lfsr[15:7]) ? lfsr[2:0] : 0) +
    (star2_enable && (&lfsr2[14:6]) ? lfsr2[2:0] : 0) +
    (star3_enable && (&lfsr3[13:7]) ? lfsr3[2:0] : 0) +
    ((star_enable && mount < vpos) ? 2 : 0) +
    ((star_enable && mount2 < vpos) ? 4 : 0);

endmodule
`default_nettype wire
