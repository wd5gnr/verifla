/*
file: send_capture_of_verifla.v
license: GNU GPL
Revision history
revision date: 20180808-1540
- include baud_clk_posedge

revision date: 2007/Jul/4; author: Laurentiu DUCA
- v01
*/


//`timescale 1ns/1ps
module send_capture_of_verifla(clk, rst_l, baud_clk_posedge,
	sc_run, ack_sc_run, sc_done,
	mem_port_B_address, mem_port_B_dout,
	xmit_doneH, xmitH, xmit_dataH);

`include "config_verifla.v"

// SC_states
parameter	
	SC_STATES_BITS=4,
	SC_STATE_IDLE=0,
	SC_STATE_ACK_SC_RUN=1,
	SC_STATE_SET_MEMADDR_TO_READ_FROM=2,
	SC_STATE_GET_MEM_OUTPUT_DATA=3,
	SC_STATE_SEND_OCTET=4,
	SC_STATE_WAIT_OCTET_SENT=5,
	SC_STATE_WORD_SENT=6;

// input
input clk, rst_l;
input baud_clk_posedge;
input sc_run;
input [LA_MEM_WORDLEN_BITS-1:0] mem_port_B_dout;
input xmit_doneH;
// output
output [LA_MEM_ADDRESS_BITS-1:0] mem_port_B_address;
output xmitH;
output [7:0] xmit_dataH;
output ack_sc_run, sc_done;
reg [LA_MEM_ADDRESS_BITS-1:0] mem_port_B_address;
reg xmitH;
reg [7:0] xmit_dataH;
reg ack_sc_run, sc_done;
// local
reg [SC_STATES_BITS-1:0] sc_state, next_sc_state;
reg [LA_MEM_ADDRESS_BITS-1:0] sc_current_address, next_sc_current_address;
reg [LA_MEM_WORDLEN_OCTETS-1:0] sc_octet_id, next_sc_octet_id;
reg [LA_MEM_WORDLEN_BITS-1:0] sc_word_bits, next_sc_word_bits;
	
// set up next value
always @(posedge clk or negedge rst_l)
begin
	if(~rst_l)
	begin
		sc_state=SC_STATE_IDLE;
		sc_current_address=0;
		sc_word_bits=0;
		sc_octet_id=0;
	end
	else
		if (baud_clk_posedge)
		begin
			sc_state=next_sc_state;
			sc_current_address=next_sc_current_address;
			sc_word_bits=next_sc_word_bits;
			sc_octet_id=next_sc_octet_id;
		end
end

// state machine
always @(sc_state or sc_run or xmit_doneH
	// not important but xilinx warnings.
	or sc_current_address or mem_port_B_dout or sc_word_bits or sc_octet_id)
begin
	// implicitly
	next_sc_state=sc_state;
	ack_sc_run=0;
	sc_done=0;
	xmit_dataH=0;
	xmitH=0;
	mem_port_B_address=sc_current_address;
	next_sc_current_address=sc_current_address;
	next_sc_word_bits=sc_word_bits;
	next_sc_octet_id=sc_octet_id;
			
	// state dependent
	case(sc_state)
	SC_STATE_IDLE:
	begin
		if(sc_run)
		begin
			next_sc_state = SC_STATE_ACK_SC_RUN;
			next_sc_current_address=LA_MEM_LAST_ADDR;
		end
		else
			next_sc_state = SC_STATE_IDLE;
	end
	SC_STATE_ACK_SC_RUN:
	begin
		ack_sc_run=1;
		next_sc_state = SC_STATE_SET_MEMADDR_TO_READ_FROM;
	end
	SC_STATE_SET_MEMADDR_TO_READ_FROM:
	begin
		mem_port_B_address=sc_current_address;
		// next clock cycle we have memory dout of our read.
		next_sc_state = SC_STATE_GET_MEM_OUTPUT_DATA;
	end		
	SC_STATE_GET_MEM_OUTPUT_DATA:
	begin
		next_sc_word_bits=mem_port_B_dout;
		// LSB first
		next_sc_octet_id=0;
		next_sc_state = SC_STATE_SEND_OCTET;
	end
	SC_STATE_SEND_OCTET:
	begin
		xmit_dataH=sc_word_bits[7:0];
		next_sc_word_bits={8'd0, sc_word_bits[LA_MEM_WORDLEN_BITS-1:8]}; //sc_word_bits>>8;
		xmitH=1;
		next_sc_octet_id=sc_octet_id+1;
		next_sc_state = SC_STATE_WAIT_OCTET_SENT;
	end
	SC_STATE_WAIT_OCTET_SENT:
	begin
		if(xmit_doneH)
		begin
			if(sc_octet_id < LA_MEM_WORDLEN_OCTETS)
				next_sc_state = SC_STATE_SEND_OCTET;
			else
				next_sc_state = SC_STATE_WORD_SENT;
		end
		else
			next_sc_state = SC_STATE_WAIT_OCTET_SENT;
	end
	SC_STATE_WORD_SENT:
	begin
		if(sc_current_address > LA_MEM_FIRST_ADDR)
		begin
			next_sc_current_address=sc_current_address-1;
			next_sc_state = SC_STATE_SET_MEMADDR_TO_READ_FROM;
		end
		else
		begin
			// done sending all captured data
			sc_done = 1;
			next_sc_state = SC_STATE_IDLE;
		end
	end
	default: // should never get here
	begin
		next_sc_state=4'bxxxx;
		sc_done=1'bx;
		xmit_dataH=1'bx;
		xmitH=1'bx;
		mem_port_B_address={LA_MEM_ADDRESS_BITS{1'bx}};
		next_sc_current_address={LA_MEM_ADDRESS_BITS{1'bx}};
		next_sc_word_bits={LA_MEM_WORDLEN_BITS{1'bx}};
		next_sc_octet_id={LA_MEM_WORDLEN_OCTETS{1'bx}};
	end
	endcase
end

endmodule
