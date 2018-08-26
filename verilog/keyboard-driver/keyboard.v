module keyboard(kbd_data_line, kbd_clk, kbd_key,
	clk, reset,
	//top_of_verifla transceiver
	uart_XMIT_dataH, uart_REC_dataH
);


input clk, reset;
//top_of_verifla transceiver
input uart_REC_dataH;
output uart_XMIT_dataH;

// App. specific
input kbd_data_line, kbd_clk;
output [7:0] kbd_key;	// register for storing keyboard data

reg [7:0] kbd_key;
reg [3:0] i; 		// initial value needs to be not equal to 0 through 7. set initial to 10.

wire negedge_kbd_clk;


// This is the keyboard driver logic (fsm).
always @ (posedge clk or posedge reset)
begin
	if(reset) 
	begin 
		i=10;
		kbd_key=8'h0; //{8'b00010010};//8'h0;
	end
	else begin
		if(negedge_kbd_clk)
		begin
			if ((i >= 0) && (i <= 7)) 
			// If i is pointing to a bit of data let us keep it.
			begin
				kbd_key = {kbd_data_line, kbd_key[7:1]};
				i = i + 1;
			end
			else if ((i == 8) || (i == 9)) 
			// Otherwise if i is pointing to the parity bit or the stop bit let us ignore it.
			begin
				i = i + 1;
			end
			else // Else we have a start bit
			begin
				i = 0;
			end
		end
	end
end


reg [2:0] kbd_clk_buf=3'b000;
always @ (posedge clk) kbd_clk_buf={kbd_clk_buf[1:0], kbd_clk};
assign negedge_kbd_clk = kbd_clk_buf[2:1]==2'b10;


// Simple counter
reg [5:0] cnt=0;
always @(posedge clk or posedge reset)
begin
	if(reset)
		cnt = 0;
	else
		if(negedge_kbd_clk)
			cnt = cnt+1;
end

// VeriFLA
top_of_verifla verifla (.clk(clk), .rst_l(!reset), .sys_run(1'b1),
				.data_in({cnt, kbd_data_line, kbd_clk, kbd_key}),
				//{6'b0, kbd_data_line, kbd_clk, kbd_key},
				// Transceiver
				.uart_XMIT_dataH(uart_XMIT_dataH), .uart_REC_dataH(uart_REC_dataH));

endmodule

// Local Variables:
// verilog-library-directories:(".", "../verifla")
// End:
