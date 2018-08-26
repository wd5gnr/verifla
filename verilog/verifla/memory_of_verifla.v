`default_nettype none
`include "config_verifla.v"
module memory_of_verifla (input clka, input rst_l, input [LA_MEM_ADDRESS_BITS-1:0] addra, 
			  input wea, input [LA_MEM_WORDLEN_BITS-1:0] dina, 
			  input [LA_MEM_ADDRESS_BITS-1:0]  addrb, 
			  output reg [LA_MEM_WORDLEN_BITS-1:0] doutb);
   
   reg [LA_MEM_WORDLEN_BITS-1:0] mem[LA_MEM_LAST_ADDR:0];
   
   always @(posedge clka)
     begin
	if (wea) mem[addra]<=dina;
     end
   always @(posedge clka)
     begin
	doutb<=mem[addrb];
     end

endmodule
   
   
