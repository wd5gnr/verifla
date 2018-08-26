/*
file: computer_input_of_verifla.v
license: GNU GPL

Revision history
revision date: 2007/Sep/03; author: Laurentiu DUCA
- USERCMD_RESET

revision date: 2007/Jul/4; author: Laurentiu DUCA
- v01
*/


module computer_input_of_verifla (clk, rst_l, 
	rec_dataH, rec_readyH, user_reset_low, user_run);
// user commands
parameter USERCMD_RESET = 8'h00,
	USERCMD_RUN = 8'h01;
// CI_states
parameter	CI_STATES_BITS=4,
	CI_STATE_IDLE=0,
	CI_STATE_START_OF_NEW_CMD=1;

// input
input clk, rst_l;
input rec_readyH;
input [7:0] rec_dataH;
// output
output user_reset_low, user_run;
reg user_reset_low, user_run;
// locals
reg [CI_STATES_BITS-1:0] ci_state, next_ci_state;
reg [7:0] ci_indata, next_ci_indata;
wire ci_new_octet_received;

// T(clk)<<T(uart_clk)
single_pulse_of_verifla sp1(.clk(clk), .reset(rst_l), .ub(rec_readyH), .ubsing(ci_new_octet_received));
	
// set up next value
always @(posedge clk or negedge rst_l)
begin
	if(~rst_l)
	begin
		ci_state=CI_STATE_IDLE;
		ci_indata=0;
	end
	else
	begin
		ci_state=next_ci_state;
		ci_indata=next_ci_indata;
	end
end

// state machine
always @(ci_new_octet_received or rec_dataH or ci_state or ci_indata)
begin
	// implicit
	next_ci_state=ci_state;
	next_ci_indata=0;
	user_reset_low=1;
	user_run=0;
	
	// state dependent
	case(ci_state)
	CI_STATE_IDLE:
	begin
		if(ci_new_octet_received)
		begin
			next_ci_indata=rec_dataH;
			next_ci_state=CI_STATE_START_OF_NEW_CMD;
		end
		else
			next_ci_state=CI_STATE_IDLE;
	end
	
	CI_STATE_START_OF_NEW_CMD:
	begin
		case(ci_indata)
		USERCMD_RESET:
		begin
			user_reset_low=0;
			next_ci_state=CI_STATE_IDLE;
		end
		USERCMD_RUN:
		begin
			user_run=1;
			next_ci_state=CI_STATE_IDLE;			
		end
		default:
		begin
			// Ignore unknown commands.
			next_ci_state=CI_STATE_IDLE;
		end
		endcase
	end	
	
	default: // should never get here
	begin
		next_ci_state=4'bxxxx;
		next_ci_indata=8'hxx;
		user_reset_low=1'bx;
		user_run=1'bx;
	end
	endcase
end

endmodule
