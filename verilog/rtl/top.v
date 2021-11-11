`default_nettype none

module top (
    input  wire       clk    ,
    input  wire       reset_n,
    output wire       hsync  ,
    output wire       vsync  ,
    output wire [2:0] rgb
);

    wire px_clk;
    wire reset;

    // Generated values for pixel clock of 31.5Mhz and 72Hz frame frecuency.
    // # icepll -i12 -o31.5
    //
    // F_PLLIN:    12.000 MHz (given)
    // F_PLLOUT:   31.500 MHz (requested)
    // F_PLLOUT:   31.500 MHz (achieved)
    //
    // FEEDBACK: SIMPLE
    // F_PFD:   12.000 MHz
    // F_VCO: 1008.000 MHz
    //
    // DIVR:  0 (4'b0000)
    // DIVF: 83 (7'b1010011)
    // DIVQ:  5 (3'b101)
    //
    // FILTER_RANGE: 1 (3'b001)
    //
    `ifdef SYNTH
        SB_PLL40_PAD #(
            .FEEDBACK_PATH("SIMPLE"  ),
            .DIVR         (4'b0000   ),
            .DIVF         (7'b1010011),
            .DIVQ         (3'b101    ),
            .FILTER_RANGE (3'b001    )
        ) uut (
            .RESETB    (1'b1  ),
            .BYPASS    (1'b0  ),
            .LOCK      (lock  ),
            .PACKAGEPIN(clk   ),
            .PLLOUTCORE(px_clk)
        );

        // Note that reset_n is connected to the physical button on the FPGA board
        // and it does NOT seem to be driven LOW during the initialisation.
        //
        // To detect initialisation we are going to use inverted PLL.LOCK instead.
        // Judging from the "LATTICE ICE Technology Library" documentation
        // PLL.LOCK is held LOW during the PLL and board initialisation.
        // See: "LATTICE ICE Technology Library" doc
        // > LOCK: Output port, when HIGH, indicates that the signal on PLLOUTGLOBAL/PLLOUTCORE
        // > is locked to the PLL source on PACKAGEPIN.
        //
        // Also see: https://github.com/YosysHQ/yosys/issues/103#issuecomment-159965426
        // > When you are using the PLLs you can directly use the PLL LOCK control
        // > output as reset signal.
        //
        wire lock;
        assign reset = !lock | !reset_n;
    `else
        assign px_clk = clk;
        assign reset = !reset_n;
    `endif


    parallax i_parallax(
        .clk  (px_clk),
        .reset(reset ),
        .hsync(hsync ),
        .vsync(vsync ),
        .rgb  (rgb   )
    );

endmodule
