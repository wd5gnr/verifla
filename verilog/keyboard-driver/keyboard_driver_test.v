`timescale 1ns / 1ps
module keyboard_driver_test(kbd_key);

`include "../verifla/common_internal_verifla.v"

// This test module is wrote
// in the following scenario: the driver is on the FPGA and the keyboard
// is attached to the FPGA development board

// Declaration
output [7:0] kbd_key;
wire [7:0] kbd_key;
// This signals must explicitly added to the simulation.
// For debugging purposes, also add the register named "i" from the keyboard driver
reg reset, clk;
reg kbd_clk, kbd_data_line;
wire uart_XMIT_dataH;
reg uart_REC_dataH=1;

reg [64:0] i;

keyboard kd (kbd_data_line, kbd_clk, kbd_key,
	clk, reset,
	//top_of_verifla transceiver
	uart_XMIT_dataH, uart_REC_dataH
);

always begin
	clk = 0;
	#5;
	clk = 1;
	#5;
end

// Reset the driver by using the reset button of the FPGA board.
initial begin
    $dumpfile("kbd.vcd");
    $dumpvars;
	reset = 0;
	#10;
	reset = 1;
	#10;
	reset = 0;	
end

// Now, simulate the keyboard.
// Consider the keyboard clock period to be about 10 units.
initial begin
	// At the begining, the line is idle for some periods.
	kbd_clk=1; kbd_data_line=1; #2050; #2050; 
	
	// When a key is pressed, the keyboard sends its scan code
	// on the data line. For the 'a' key, the scan code is 1Ch=00011100b.
	// The order is LSb first, so the bits are sent in the following order: 00111000.
	// Simulate pressing the 'a' key.
	// Send start bit.
	kbd_clk=1; #250; kbd_data_line=0; #250; kbd_clk=0; #500;
	// Send the scan code
	kbd_clk=1; #250; kbd_data_line=0; #250; kbd_clk=0; #500;
	kbd_clk=1; #250; kbd_data_line=0; #250; kbd_clk=0; #500;
	kbd_clk=1; #250; kbd_data_line=1; #250; kbd_clk=0; #500;
	kbd_clk=1; #250; kbd_data_line=1; #250; kbd_clk=0; #500;
	kbd_clk=1; #250; kbd_data_line=1; #250; kbd_clk=0; #500;
	kbd_clk=1; #250; kbd_data_line=0; #250; kbd_clk=0; #500;
	kbd_clk=1; #250; kbd_data_line=0; #250; kbd_clk=0; #500;
	kbd_clk=1; #250; kbd_data_line=0; #250; kbd_clk=0; #500;
	// Send the parity bit which is '1' for the 'a' key.
	kbd_clk=1; #250; kbd_data_line=1; #250; kbd_clk=0; #500;
	// Send the stop bit.
	kbd_clk=1; #250; kbd_data_line=1; #250; kbd_clk=0; #500;
	// Put the line idle for two periods.
	kbd_clk=1; kbd_data_line=1; #2050; #2050;
	#1000;
	// When the 'a' key - that is now pressed,
	// will be released, then the keyboard will send F0h, 1Ch.
	// We do not simulate this because the process is similar.

`ifdef DEBUG_LA
	//$display("value: %b", {{{(LA_IDENTICAL_SAMPLES_BITS-1){1'b0}}, 1'b1}, {LA_DATA_INPUT_WORDLEN_BITS{1'b0}}});
	for(i = 0; i <= LA_MEM_LAST_ADDR; i = i + 1) begin
		//$display("i=%d m2[i]=%d m1[i]=%b", i, kd.verifla.mi.m2[i], kd.verifla.mi.m1[i]);
		$display("%d %h %h %h %h", i, kd.verifla.mi.mem[i][31:24], kd.verifla.mi.mem[i][22:16], 
			kd.verifla.mi.mem[i][15:8], kd.verifla.mi.mem[i][7:0]);
	end
	//$display("m[%d]=%d", LA_MEM_LAST_ADDR, kd.verifla.mi.mem[LA_MEM_LAST_ADDR]);
`endif
	$stop;
end

endmodule
