module top (
	input CLK12M,
	input USER_BTN,
	output [7:0] LED,
	output SEN_SDI,
	output SEN_SPC,
	input SEN_SDO,
	output SEN_CS,
	output [8:1] PIO,
	output UART_TXD,
	input UART_RXD
);

parameter div_coef = 32'd5000;

wire nrst;
assign nrst = USER_BTN;


wire [31:0] spi_mosi_data;
wire [31:0] spi_miso_data;
wire [5:0] spi_nbits;
wire spi_request;
wire spi_ready;
wire dir;


// add logic analyzer
top_of_verifla_nodef la(.clk(CLK12M), .cqual(divider_out), .rst_l(nrst), 
					.sys_run(1'b0), .data_in({LED, foo[dir?4'b1111-pos:pos]}),
                      .uart_XMIT_dataH(UART_TXD), .uart_REC_dataH(UART_RXD), .trigqual(1'b1),
                      .exttrig(1'b0));


sequencer U1 (
	.clk_in(CLK12M),
	.nrst(nrst),
	
	.spi_mosi_data(spi_mosi_data),
	.spi_miso_data(spi_miso_data),
	.spi_nbits(spi_nbits),
	
	.spi_request(spi_request),
	.spi_ready(spi_ready),
	
	.led_out(/*LED*/), // Just for debugging
	.direction(dir)
);
	
spi_master U2 (
	.clk_in(CLK12M),
	.nrst(nrst),
	
	.spi_sck(SEN_SPC),
	.spi_mosi(SEN_SDI),
	.spi_miso(SEN_SDO),
	.spi_csn(SEN_CS),
	
	.mosi_data(spi_mosi_data),
	.miso_data(spi_miso_data),
	.nbits(spi_nbits),    // nbits==0 -> 1 bit transfer
	
	.request(spi_request),
	.ready(spi_ready)
);

assign PIO[1] = SEN_SPC;
assign PIO[2] = SEN_SDI;
assign PIO[3] = SEN_SDO;
assign PIO[4] = SEN_CS;


// Frequency divider 
reg [31:0] divider;
reg divider_out;

always @(posedge CLK12M or negedge nrst) begin
	if (!nrst) begin
		divider <= 32'b0;
		divider_out <= 1'b0;
	end else begin
		if (divider != div_coef) begin
			divider <= divider + 1;
			divider_out <= 1'b0;
		end else begin
			divider <= 32'b0;
			divider_out <= 1'b1;
		end
	end
end

// Switch columns for each character (addr_lsb)
// Char_inc at the end of each character
reg [2:0] addr_lsb;
reg char_inc;

always @(posedge CLK12M or negedge nrst) begin
	if (!nrst) begin
		addr_lsb <= 3'b0;
		char_inc <= 1'b0;
	end else begin
		if (divider_out) begin
			if (addr_lsb == 3'b101) begin
				addr_lsb <= 3'b0;
				char_inc <= 1'b1;
			end else begin
				addr_lsb <= addr_lsb+1;
				char_inc <= 1'b0;
			end
		end else begin
			char_inc <= 1'b0;
		end
	end
end

// Switch characters in string
reg [3:0] pos;

always @(posedge CLK12M or negedge nrst) begin
	if (!nrst) begin
		pos <= 4'b0;
	end else begin
		if (char_inc) begin
			if (pos == 4'b1111) begin
				pos <= 4'b0;
			end else begin
				pos <= pos+1;
			end	
		end
	end
end

wire [7:0] foo [0:15];
assign foo[0]  = "H";
assign foo[1]  = "A";
assign foo[2]  = "C";
assign foo[3]  = "K";
assign foo[4]  = "A";
assign foo[5]  = "D";
assign foo[6]  = "A";
assign foo[7]  = "Y";
assign foo[8]  = "H";
assign foo[9]  = "A";
assign foo[10] = "C";
assign foo[11] = "K";
assign foo[12] = "A";
assign foo[13] = "D";
assign foo[14] = "A";
assign foo[15] = "Y";

// Assign ROM address depending on direction
reg [9:0] addr;

always @(posedge CLK12M or negedge nrst) begin
	if (!nrst) begin
		addr <= 10'b0;
	end else begin
		if (dir) begin
			addr <= {foo[4'b1111 - pos] - 'h20, 3'b101 - addr_lsb};
		end else begin
			addr <= {foo[pos] - 'h20, addr_lsb};
		end
	end
end

wire [7:0] rom_out;

font_rom ROM0
(
	.address(addr),
	.clock(CLK12M),
	.q(rom_out)
);


// Reverse bits
assign LED[0] = rom_out[7];
assign LED[1] = rom_out[6];
assign LED[2] = rom_out[5];
assign LED[3] = rom_out[4];

assign LED[4] = rom_out[3];
assign LED[5] = rom_out[2];
assign LED[6] = rom_out[1];
assign LED[7] = rom_out[0];

endmodule
