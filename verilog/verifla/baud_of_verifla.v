
module baud_of_verifla(
			sys_clk,
			sys_rst_l,
			baud_clk_posedge
		);


`include "config_verifla.v"


input 			sys_clk;
input			sys_rst_l;
output			baud_clk_posedge;
reg baud_clk;
reg baud_clk_posedge;

reg [BAUD_COUNTER_SIZE-1:0] counter=0; //{BAUD_COUNTER_SIZE{1'b0}};

always @(posedge sys_clk or negedge sys_rst_l)
begin
	if(~sys_rst_l) begin
		baud_clk <= 0;
		baud_clk_posedge <= 0;
		counter <= 0;
	end else if (counter < T2_div_T1_div_2) begin
		counter <= counter + 1;
		baud_clk <= baud_clk;
		baud_clk_posedge <= 0;
	end else begin
		if(~baud_clk) // baud_clk will become 1
			baud_clk_posedge <= 1;
		counter <= 0;
		baud_clk <= ~baud_clk;
	end
end

/*
reg [2:0] baud_vec=3'b000;
always @(posedge clk) baud_vec = {baud_vec[1:0], baud_clk};
wire baud_clk_posedge=(baud_vec[2:1]=2'b01;
wire baud_clk_negedge=(baud_vec[2:1]=2'b10;
*/

endmodule
