/*
Update: Laurentiu Duca, 20180808_1200:
	- consider baud_clk_posedge
*/
module uart_of_verifla	(	sys_clk,
				sys_rst_l,
				baud_clk_posedge,

				// Transmitter
				uart_XMIT_dataH,
				xmitH,
				xmit_dataH,
				xmit_doneH,

				// Receiver
				uart_REC_dataH,
				rec_dataH,
				rec_readyH		
			);		

input			sys_clk;
input			sys_rst_l;
output		baud_clk_posedge;

// Trasmitter
output			uart_XMIT_dataH;
input			xmitH;
input	[7:0]	xmit_dataH;
output			xmit_doneH;

// Receiver
input			uart_REC_dataH;
output	[7:0]	rec_dataH;
output			rec_readyH;

wire 			baud_clk_posedge;
wire	[7:0]	rec_dataH;
wire			rec_readyH;



// Instantiate the Transmitter
u_xmit_of_verifla txd1 (
		.clk_i(sys_clk), 
		.rst_i(!sys_rst_l), 
		.baud_clk_posedge(baud_clk_posedge),
		.data_i(xmit_dataH), 
		.wen_i(xmitH), 
		.txd_o(uart_XMIT_dataH), 
		.tre_o(xmit_doneH)
	);
/*
u_xmit  iXMIT(  .sys_clk(baud_clk),
				.sys_rst_l(sys_rst_l),

				.uart_xmitH(uart_XMIT_dataH),
				.xmitH(xmitH),
				.xmit_dataH(xmit_dataH),
				.xmit_doneH(xmit_doneH)
			);
*/

// Instantiate the Receiver
u_rec_of_verifla rxd1(
		.clk_i(sys_clk),
		.rst_i(!sys_rst_l),//system signal
		.baud_clk_posedge(baud_clk_posedge),
		.rxd_i(uart_REC_dataH),//serial data in
		.rdy_o (rec_readyH), .data_o(rec_dataH) //data ready and parallel data out signal
		);
/*
u_rec iRECEIVER (// system connections
				.sys_rst_l(sys_rst_l),
				.sys_clk(baud_clk),
				// uart
				.uart_dataH(uart_REC_dataH),
				.rec_dataH(rec_dataH),
				.rec_readyH(rec_readyH)
				);
*/

// Instantiate the Baud Rate Generator

baud_of_verifla baud1(	.sys_clk(sys_clk),
			.sys_rst_l(sys_rst_l),		
			.baud_clk_posedge(baud_clk_posedge)
		);

/*
reg [2:0] baud_clk_vec=0;
always @(posedge sys_clk or negedge sys_rst_l)
begin
	if(~sys_rst_l)
		baud_clk_vec = 0;
	else
		baud_clk_vec = {baud_clk_vec[1:0], baud_clk};
end
wire baud_clk_posedge;
assign baud_clk_posedge=baud_clk_vec[2:1]==2'b01;
*/
endmodule
