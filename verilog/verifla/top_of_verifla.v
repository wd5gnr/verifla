/*
file: top_of_verifla.v
license: GNU GPL
Revision history
revision date: 2007/Sep/03; author: Laurentiu DUCA
- sys_run: an internal possible run command
- combined_reset_low which allows the user to reset the monitor

revision date: 2007/Jul/4; author: Laurentiu DUCA
- v01
*/


module top_of_verifla(input clk, input cqual=1'b1, input rst_l, input sys_run=1'b0, 
		      input [LA_DATA_INPUT_WORDLEN_BITS-1:0] data_in,
		      output uart_XMIT_dataH, input uart_REC_dataH, 
		      output armed, output triggered, input trigqual=1'b1,
		      input exttrig=0 );
				
`include "config_verifla.v"

// App. specific.
wire [LA_MEM_WORDLEN_BITS-1:0] mem_port_A_data_in, mem_port_B_dout;
wire [LA_MEM_ADDRESS_BITS-1:0] mem_port_A_address, mem_port_B_address;
wire mem_port_A_wen;
wire user_reset_low, user_run, mon_run;
wire combined_reset_low;
wire sc_run, ack_sc_run, sc_done;

// Transceiver
wire [7:0] xmit_dataH;
wire xmit_doneH;
wire xmitH;
// Receiver
wire [7:0] rec_dataH;
wire rec_readyH;
// Baud
wire baud_clk_posedge;

uart_of_verifla iUART (clk, rst_l, baud_clk_posedge,
				// Transmitter
				uart_XMIT_dataH, xmitH, xmit_dataH, xmit_doneH,
				// Receiver
				uart_REC_dataH, rec_dataH, rec_readyH);

memory_of_verifla mi (
	.addra(mem_port_A_address),	.addrb(mem_port_B_address),
	.clka(clk),	.rst_l(rst_l),
	.dina(mem_port_A_data_in), 	.doutb(mem_port_B_dout), 
	.wea(mem_port_A_wen));

assign combined_reset_low=(rst_l && user_reset_low);
assign mon_run = (sys_run || user_run);



computer_input_of_verifla ci (clk, rst_l, 
	rec_dataH, rec_readyH, user_reset_low, user_run);
monitor_of_verifla mon (clk, cqual, combined_reset_low,
		mon_run, data_in, 
		mem_port_A_address, mem_port_A_data_in, mem_port_A_wen,
			ack_sc_run, sc_done, sc_run,armed,triggered,trigqual,exttrig);
// send_capture_of_verifla must use the same reset as the uart.
send_capture_of_verifla sc (clk, rst_l, baud_clk_posedge,
	sc_run, ack_sc_run, sc_done,
	mem_port_B_address, mem_port_B_dout,
	xmit_doneH, xmitH, xmit_dataH);

endmodule

