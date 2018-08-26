// Update: 20180814_1555, author: Laurentiu Duca
// User readable form.
// Create Date:    16:17:26 02/23/2007 
// Additional Comments: single pulse from a multi-periods-contiguos pulse
// Author: Laurentiu Duca
// License: GNU GPL

`timescale 1ns / 1ps

module single_pulse_of_verifla(clk, reset, ub, ubsing);
input clk, reset;
input ub;
output ubsing;


reg next_state, state;
reg ubsing_reg, next_ubsing_reg;

assign ubsing = ubsing_reg;
  
always @(posedge clk or negedge reset)
begin
	if (~reset) begin
			state <= 0;
			ubsing_reg <= 0;
	end else begin
			state <= next_state;
			ubsing_reg <= next_ubsing_reg;
	end
end

always @(*)
begin
		next_state <= state;
		next_ubsing_reg <= 0;
		case (state)
		0: if (ub == 1) begin
				next_state <= 1;
				next_ubsing_reg <= 1;
			end
		1: if (ub == 0)
				next_state <= 0;
		endcase
end


/*
Truth table
====
before (posedge clk) | after (posedge clk)
ub / state(q1q0) | state(q1q0) / ubsing
0 / 00 | 00 / 0
1 / 00 | 01 / 1
x / 01 | 10 / 0
0 / 10 | 00 / 0
1 / 10 | 10 / 0

Notes:
- works only if the (posedge ub) comes 2 clk periods after the prevoius (negedge ub).
- after reset, ub can be either 0 or 1.
*/

/*
reg [1:0] q;
assign ubsing = q[0];

always @ (posedge clk or negedge reset)
begin

if(~reset)
begin
	q[0] <= 0;
	q[1] <= 0;
end
else
begin
	q[0] <= ~q[0] && ub && ~q[1];
	q[1] <= q[0] || (~q[0] && ub && q[1]);
end
end
*/

endmodule
