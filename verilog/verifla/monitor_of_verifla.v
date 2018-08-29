`default_nettype none
/*
file: monitor_of_verifla.v
license: GNU GPL
Revision history

20180827
  - Added trigger enable and external trigger
20180823
 - Updates to 2.2 from upstream (Al Williams)
 - However, adding mon_run_reg changes caused LA to be unresponsive on Lattice iCe40 w/Icestorm
20180820 
 - Fixes and changes by Al Williams 
 
20180814-1600
- LA_MEM_CLEAN_BEFORE_RUN is parameter now
20180808-1700
- ifdef LA_MEM_CLEAN_BEFORE_RUN
revision date: 20180730-1500; Laurentiu Duca
- redesign of mem struct
- the bt_queue_tail_address is wrote at the end of capture.
revision date: 2007/Sep/03; author: Laurentiu DUCA
- the bt_queue_head_address is wrote at the end of capture.
- zero all memory at a mon_run (if LA_MEM_CLEAN_BEFORE_RUN).
- note that _at_ means after trigger event and _bt_ means before trigger event

revision date: 2007/Jul/4; author: Laurentiu DUCA
- v01
*/


module monitor_of_verifla (clk, cqual, rst_l, 
	mon_run, data_in, 
	mem_port_A_address, mem_port_A_data_in, mem_port_A_wen,
			   ack_sc_run, sc_done, sc_run, armed, triggered,
			   trigqual, exttrig);
   
	
`include "config_verifla.v"

// MON_states
parameter	
	MON_STATES_BITS=4,
	MON_STATE_IDLE=0,
	MON_STATE_DO_MEM_CLEAN=1,
	MON_STATE_PREPARE_RUN=2,
	MON_STATE_WAIT_TRIGGER_MATCH=3,
	MON_STATE_AFTER_TRIGGER=4,
	MON_STATE_DATA_CAPTURED=5,
	MON_STATE_SC_RUN=6,
	MON_STATE_WAIT_SC_DONE=7;

// input
input clk, cqual, rst_l;
input [LA_DATA_INPUT_WORDLEN_BITS-1:0] data_in;
input mon_run, ack_sc_run, sc_done;
input trigqual, exttrig;
   
// output
output [LA_MEM_ADDRESS_BITS-1:0] mem_port_A_address;
output [LA_MEM_WORDLEN_BITS-1:0] mem_port_A_data_in;
output mem_port_A_wen;
output sc_run, armed, triggered;
reg [LA_MEM_ADDRESS_BITS-1:0] mem_port_A_address;
reg [LA_MEM_WORDLEN_BITS-1:0] mem_port_A_data_in;
reg mem_port_A_wen;
reg mon_run_reg, sc_run, next_sc_run;
reg armed, triggered;
   

// local
reg [MON_STATES_BITS-1:0] mon_state, next_mon_state;
reg [LA_MAX_SAMPLES_AFTER_TRIGGER_BITS-1:0] 
	next_mon_samples_after_trigger, mon_samples_after_trigger;
   reg [LA_MEM_ADDRESS_BITS-1:0] 	    next_mon_write_address, mon_write_address;
   
//, last_tail,next_last_tail;
reg [LA_MEM_ADDRESS_BITS-1:0] next_bt_queue_tail_address, bt_queue_tail_address;
reg [LA_DATA_INPUT_WORDLEN_BITS-1:0] mon_old_data_in, 
	mon_current_data_in; //={LA_DATA_INPUT_WORDLEN_BITS{1'b0}};
reg [LA_IDENTICAL_SAMPLES_BITS-1:0] mon_clones_nr, next_mon_clones_nr;
   



// Register the input data
// such that mon_current_data_in is constant the full clock period.
always @(posedge clk or negedge rst_l)
begin
	if(~rst_l)
	begin
		mon_old_data_in <= 0;
		mon_current_data_in <= 0;
// This line causes the state machine to hang when using Yosys/Arachne for ice40
// Not sure why
	    //    mon_run_reg<=0;
	   
	   
	end

	else 
	  begin
	     mon_run_reg<=mon_run;
	     if (cqual) begin
		mon_old_data_in <= mon_current_data_in;
		mon_current_data_in <= data_in;
	     end
	  end
end
	
// set new values
always @(posedge clk or negedge rst_l)
begin
	if(~rst_l)
	begin
		mon_state <= MON_STATE_IDLE;
		sc_run <= 0;
		mon_write_address <= LA_MEM_FIRST_ADDR;
		bt_queue_tail_address <= 0;
		mon_samples_after_trigger <= 0;
		mon_clones_nr <= 1;
//	        last_tail<=0;
	        armed<=0;
  	        triggered<=0;
	   
	   
	end
	else 
	  begin
  	           if (next_mon_state==MON_STATE_AFTER_TRIGGER) triggered<=1'b1;
	           if (next_mon_state==MON_STATE_IDLE) begin
		      armed<=1'b0;
		      triggered<=1'b0;
		   end

	     if ((mon_state!=MON_STATE_WAIT_TRIGGER_MATCH && mon_state!=MON_STATE_AFTER_TRIGGER) || cqual) begin
	           sc_run <= next_sc_run;
	            mon_state <= next_mon_state;

		   mon_write_address <= next_mon_write_address;
		   bt_queue_tail_address <= next_bt_queue_tail_address;
		   mon_samples_after_trigger <= next_mon_samples_after_trigger;
		   mon_clones_nr <= next_mon_clones_nr;
		   if (next_mon_state==MON_STATE_WAIT_TRIGGER_MATCH) begin
		      //		      last_tail<=mem_port_A_address; 
		      armed<=1'b1;
		   end
	     end
	end
end


// continuous assignments
wire [LA_MEM_ADDRESS_BITS-1:0] one_plus_mon_write_address = (mon_write_address+1);
wire [LA_IDENTICAL_SAMPLES_BITS-1:0] oneplus_mon_clones_nr = (mon_clones_nr+1);
wire data_in_changed = (mon_current_data_in != mon_old_data_in);
wire last_mem_addr_before_trigger = (mon_write_address == LA_MEM_LAST_ADDR_BEFORE_TRIGGER);
wire not_maximum_mon_clones_nr = (mon_clones_nr < LA_MAX_IDENTICAL_SAMPLES);


//  mon_prepare_run is called from states MON_STATE_IDLE and MON_STATE_PREPARE_RUN
task mon_prepare_run;
begin
		// we share the same clock as memory.
		mem_port_A_address=LA_MEM_FIRST_ADDR;
		mem_port_A_data_in={{(LA_IDENTICAL_SAMPLES_BITS-1){1'b0}}, 1'b1, mon_current_data_in};
		mem_port_A_wen<=1;
		next_mon_write_address=LA_MEM_FIRST_ADDR;
		next_mon_clones_nr=2;
		next_mon_state = MON_STATE_WAIT_TRIGGER_MATCH;
end
endtask	


// state machine
always @(*)
/*
	mon_state or  mon_run
	or ack_sc_run or sc_done or sc_run
	// eliminate warnings
	or mon_write_address or bt_queue_tail_address or mon_samples_after_trigger
	or mon_current_data_in or mon_old_data_in or mon_clones_nr
	or data_in_changed or oneplus_mon_clones_nr or one_plus_mon_write_address
	or not_maximum_mon_clones_nr
	or last_mem_addr_before_trigger)
*/
begin
	// implicit
	next_mon_state=mon_state;
	next_sc_run=sc_run;
	next_mon_write_address=mon_write_address;
	next_bt_queue_tail_address=bt_queue_tail_address;
	next_mon_samples_after_trigger=mon_samples_after_trigger;
	next_mon_clones_nr = mon_clones_nr;
	mem_port_A_address=0;
	mem_port_A_data_in=0;
	mem_port_A_wen=0;
   
	
	// state dependent
	case(mon_state)
	MON_STATE_IDLE:
	begin
		if(mon_run_reg)
		begin
			if(LA_MEM_CLEAN_BEFORE_RUN) begin
				next_mon_write_address=LA_MEM_FIRST_ADDR;
				next_mon_state=MON_STATE_DO_MEM_CLEAN;
			end else
				mon_prepare_run;
		end
		else
			next_mon_state=MON_STATE_IDLE;
	end
	
	MON_STATE_DO_MEM_CLEAN:
	begin
		mem_port_A_address=mon_write_address;
		mem_port_A_data_in=LA_MEM_EMPTY_SLOT;
		mem_port_A_wen=1;
		if(mon_write_address < LA_MEM_LAST_ADDR)
		begin
			next_mon_write_address=mon_write_address+1;
			next_mon_state = MON_STATE_DO_MEM_CLEAN;
		end
		else
			// at the new posedge clock, will clean memory at its last address 
			next_mon_state = MON_STATE_PREPARE_RUN;
	end
	
	MON_STATE_PREPARE_RUN:
	begin
		mon_prepare_run;
	end
	
	MON_STATE_WAIT_TRIGGER_MATCH:
	begin
		// circular queue
	        if(exttrig==1'b0 && (trigqual==1'b0 || (mon_current_data_in & LA_TRIGGER_MASK) != 
			(LA_TRIGGER_VALUE & LA_TRIGGER_MASK)))
		begin
			next_mon_state = MON_STATE_WAIT_TRIGGER_MATCH;
			mem_port_A_wen = 1;
		        mem_port_A_address = (data_in_changed || ~not_maximum_mon_clones_nr)?
					(last_mem_addr_before_trigger?LA_MEM_FIRST_ADDR : one_plus_mon_write_address):mon_write_address;
		   

			mem_port_A_data_in = data_in_changed ? 
											{{(LA_IDENTICAL_SAMPLES_BITS-1){1'b0}}, 1'b1, mon_current_data_in} :
											(not_maximum_mon_clones_nr ? {mon_clones_nr, mon_current_data_in} :
												{{(LA_IDENTICAL_SAMPLES_BITS-1){1'b0}}, 1'b1, mon_current_data_in});
			next_mon_clones_nr = data_in_changed ? 2 :
											(not_maximum_mon_clones_nr ? oneplus_mon_clones_nr : 2);
			next_mon_write_address = data_in_changed ?
											(last_mem_addr_before_trigger ? LA_MEM_FIRST_ADDR: one_plus_mon_write_address) :
											(not_maximum_mon_clones_nr ? mon_write_address : 
												(last_mem_addr_before_trigger ? LA_MEM_FIRST_ADDR : one_plus_mon_write_address));
		end
		else begin
			// trigger matched
			next_mon_state=MON_STATE_AFTER_TRIGGER;
			mem_port_A_address=LA_TRIGGER_MATCH_MEM_ADDR;
			mem_port_A_data_in = {{{(LA_IDENTICAL_SAMPLES_BITS-1){1'b0}}, 1'b1}, mon_current_data_in};
			mem_port_A_wen=1;
			next_mon_write_address=LA_TRIGGER_MATCH_MEM_ADDR;
			next_mon_clones_nr=2;
   			next_bt_queue_tail_address = mon_write_address; 		   
			next_mon_samples_after_trigger=1;
		end
	end

	MON_STATE_AFTER_TRIGGER:
	begin
		if((mon_samples_after_trigger < LA_MAX_SAMPLES_AFTER_TRIGGER) &&
			(mon_write_address < LA_MEM_LAST_ADDR))
		begin
			mem_port_A_wen = 1;	
			mem_port_A_address = data_in_changed ?	one_plus_mon_write_address : 
											(not_maximum_mon_clones_nr ? mon_write_address : one_plus_mon_write_address);
			mem_port_A_data_in = data_in_changed ? {{(LA_IDENTICAL_SAMPLES_BITS-1){1'b0}}, 1'b1, mon_current_data_in} :
											(not_maximum_mon_clones_nr ? {mon_clones_nr, mon_current_data_in} :
												{{(LA_IDENTICAL_SAMPLES_BITS-1){1'b0}}, 1'b1, mon_current_data_in});
			next_mon_clones_nr = data_in_changed ? 2 :
											(not_maximum_mon_clones_nr ? oneplus_mon_clones_nr : 2);
			next_mon_write_address = data_in_changed ? one_plus_mon_write_address :
											(not_maximum_mon_clones_nr ? mon_write_address : one_plus_mon_write_address);
			next_mon_samples_after_trigger=mon_samples_after_trigger+1;
			next_mon_state=MON_STATE_AFTER_TRIGGER;
		end
		else begin
				mem_port_A_wen=0;
				next_mon_state=MON_STATE_DATA_CAPTURED;
		end			
	end

	MON_STATE_DATA_CAPTURED:
	begin
			// Save bt_queue_tail_address
			mem_port_A_address = LA_BT_QUEUE_TAIL_ADDRESS;
// change to our expressly saved old value
//			mem_port_A_data_in =
//				{{(LA_MEM_WORDLEN_BITS-LA_MEM_ADDRESS_BITS){1'b0}}, 
//				  last_tail};
// Duca original code
	   mem_port_A_data_in={{(LA_MEM_WORDLEN_BITS-LA_MEM_ADDRESS_BITS){1'b0}},next_bt_queue_tail_address};
	   
			mem_port_A_wen = 1;
			next_mon_state=MON_STATE_SC_RUN;
	end
	
	MON_STATE_SC_RUN:
	begin
			next_mon_state=MON_STATE_WAIT_SC_DONE;
			next_sc_run=1;
	end
	MON_STATE_WAIT_SC_DONE:
	begin
		// sc_run must already be 1, when entering state MON_STATE_SEND_CAPTURE.
		if(ack_sc_run)
			next_sc_run=0;
		if((sc_run == 0) && (sc_done))
			next_mon_state=MON_STATE_IDLE;	
		else
			next_mon_state=MON_STATE_WAIT_SC_DONE;	
	end
	
	
	default: // should never get here
	begin
		next_mon_state=4'bxxxx;
		next_sc_run=1'bx;
		next_mon_write_address={LA_MEM_ADDRESS_BITS{1'bx}};
		next_bt_queue_tail_address={(LA_MEM_ADDRESS_BITS){1'bx}};
		next_mon_samples_after_trigger={LA_MAX_SAMPLES_AFTER_TRIGGER_BITS{1'bx}};
		next_mon_clones_nr={LA_IDENTICAL_SAMPLES_BITS{1'bx}};
		mem_port_A_address={LA_MEM_ADDRESS_BITS{1'bx}};
	   mem_port_A_data_in={LA_MEM_WORDLEN_BITS{1'bx}};
	   mem_port_A_wen=1'bx;
	end
	endcase
end

			
endmodule
