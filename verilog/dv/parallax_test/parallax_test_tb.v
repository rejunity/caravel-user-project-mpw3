// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

`include "uprj_netlists.v"
`include "caravel_netlists.v"
`include "spiflash.v"

module parallax_test_tb;
	reg clock;
	reg RSTB;
	reg CSB;

	reg power1, power2;

	wire gpio;
	wire [37:0] mprj_io;
	wire [15:0] checkbits;

	wire hsync;
	wire vsync;
	wire [2:0] rgb;

	assign checkbits = mprj_io[31:16];
	assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;

	assign hsync = mprj_io[8];
	assign vsync = mprj_io[9];
	assign rgb = mprj_io[12:10];

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("parallax_test.vcd");
		$dumpvars(0, parallax_test_tb);

		// PIXEL_CLK = 31500 (31.74us) @70?
		// 832 x 520 = 432640 dots
		// HSYNC: ^^^^ [24] ____ [64] ^^^^ ... 832
		// VSYNC: ^^^^ [ 9] ____ [12] ^^^^ ... 520

		// .hsync(io_out[8]),  // skip 0..7 pins
		// .vsync(io_out[9]),
		// .rgb(io_out[12:10]),


		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (100) begin
			repeat (832*10) @(posedge clock);
			$display("+ 10 linea (8320 cycles)");
		end
		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Test Mega-Project IO (GL) Failed");
		`else
			$display ("Monitor: Timeout, Test Mega-Project IO (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	always @(mprj_io) begin
		#1 $display("MPRJ-IO state = %b ", mprj_io[12:8]);
	end

/*	initial begin
		wait(checkbits == 16'h AB60);
		$display("Monitor: Test 2 MPRJ-Logic Analyzer Started");
		wait(checkbits == 16'h AB61);
		$display("Monitor: Test 2 MPRJ-Logic Analyzer Passed");
		$finish;
	end
*/
	initial begin
		// Observe Output pins [9:8]: HSYNC & VSYNC
		//wait(mprj_io_0[9:8] == 2'b00);
		//wait(mprj_io_0[9:8] == 2'b01);
		wait(hsync == 0);
		wait(hsync == 1);

		repeat (100) begin
			wait(hsync == 0);
			wait(hsync == 1);
			$display("Line Passed");
		end

		`ifdef GL
		$display("Monitor: Test 1 Mega-Project IO (GL) Passed");
		`else
		$display("Monitor: Test 1 Mega-Project IO (RTL) Passed");
		`endif
		$finish;
	end

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	    	// Release reset
		#170000;
		CSB = 1'b0;		// CSB can be released
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
	end

    	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD1V8;
    	wire VDD3V3;
	wire VSS;

	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("parallax_test.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),
		.io3()
	);

endmodule
`default_nettype wire
