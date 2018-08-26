
/* 
Update: Laurentiu Duca, 20180808_1200:
	- consider baud_clk_posedge
Update: Laurentiu Duca, 20180724_1550: 
   - removed "rdy_o   <= 1'b0;" from idle state 
	and moved to STA_CHECK_START_BIT.
	- sample in the middle of the data bit
	- correct init values and sizes
*/			

/////////////////////////////////////////////////////////////////////
////  Author: Zhangfeifei                                        ////
////                                                             ////
////  Advance Test Technology Laboratory,                        ////
////  Institute of Computing Technology,                         ////
////  Chinese Academy of Sciences                                ////
////                                                             ////
////  If you encountered any problem, please contact :           ////
////  Email: zhangfeifei@ict.ac.cn or whitewill@opencores.org    ////
////  Tel: +86-10-6256 5533 ext. 5673                            ////
////                                                             ////
////  Downloaded from:                                           ////
////     http://www.opencores.org/pdownloads.cgi/list/ucore      ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2005-2006 Zhangfeifei                         ////
////                         zhangfeifei@ict.ac.cn               ////
////                                                             ////
////                                                             ////
//// This source file may be used and distributed freely without ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and any derivative work contains the  ////
//// original copyright notice and the associated disclaimer.    ////
////                                                             ////
//// Please let the author know if it is used                    ////
//// for commercial purpose.                                     //// 
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
////                                                             ////
//// Date of Creation: 2005.12.3                                 ////
////                                                             ////
//// Version: 0.0.1                                              ////
////                                                             ////
//// Description: rx module of the uart module,data format is    ////
////              8bits data,1 bits stop bit,and no parity check ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Change log:                                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

module u_rec_of_verifla(
		clk_i,rst_i,//system signal
		baud_clk_posedge,
		rxd_i,//serial data in
		rdy_o,data_o //data ready and parallel data out signal
		);
 
  parameter // state difinition
     STA_IDLE = 0,
     STA_CHECK_START_BIT = 1,
     STA_RECEIVE = 2;
 
  input clk_i;
  input rst_i;
  input baud_clk_posedge;
  input rxd_i;
 
  output rdy_o;
  output [7:0] data_o;
 
  reg rdy_o;
  reg [7:0] data_o;
   
  reg [7:0] rsr;//reciving shift register
  reg [3:0] num_of_rec;
  
  reg [1:0] reg_sta;
 
  //the counter to count the clk in
  reg [3:0] count;
  reg count_c;//the carry of count
  
  always @(posedge clk_i or posedge rst_i)
  begin
    if(rst_i)
    begin 
      data_o     <= 8'b0;
      rdy_o      <= 1'b0;            
      rsr        <= 8'h0;
      num_of_rec <= 4'b0;
      count      <= 4'b0;
      count_c    <= 1'b0;
      reg_sta    <= STA_IDLE;
    end
    else begin
		if(baud_clk_posedge)
			case (reg_sta)
			STA_IDLE:
			begin
			  num_of_rec <= 4'd0;
			  count      <= 4'd0;
			  if(!rxd_i) 
				 reg_sta  <= STA_CHECK_START_BIT;//recive a start bit
			  else 
				 reg_sta  <= STA_IDLE;
			end
			STA_CHECK_START_BIT:
			begin
			  if(count >= 7)
			  begin
				 count   <= 0;
				 if(!rxd_i) begin
					//has passed 8 clk and rxd_i is still zero,then start bit has been confirmed
					rdy_o   <= 1'b0;
					reg_sta <= STA_RECEIVE;
				 end
				 else 
					reg_sta <= STA_IDLE;
			  end
			  else begin
				 reg_sta <= STA_CHECK_START_BIT;
				 count   <= count +1;
			  end
			end
			STA_RECEIVE:
			begin
			  {count_c,count} <= count +1;
			  //has passed 16 clk after the last bit has been checked,sampling a bit
			  if(count_c)
			  begin
				 if(num_of_rec <=4'd7)
				 begin //sampling the received bit
					rsr        <= {rxd_i,rsr[7:1]};
					num_of_rec <= num_of_rec +1;
					reg_sta    <= STA_RECEIVE;  
				 end
				 else begin//sampling the stop bit
					//if(rxd_i)//if stop bit exist
					//begin
						data_o  <= rsr;
						rdy_o   <= 1'b1;
					//end
					reg_sta    <= STA_IDLE;
				 end
			  end
			end
			endcase
    end
  end
  
endmodule
