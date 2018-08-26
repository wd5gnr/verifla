/*
Update: Laurentiu Duca, 20180808_1200:
	- consider baud_clk_posedge
Update: Laurentiu Duca, 20180724_1550:
	- In state STA_TRANS, put num_of_trans <= 4'd8 instead of 7.
	in order to send stop bit.
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
//// Description: tx module of the uart module,data format is    ////
////              8bits data,1 bits stop bit,and no parity check ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Change log:                                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

module u_xmit_of_verifla(
		clk_i,rst_i,//system signal
		baud_clk_posedge,
		data_i,wen_i,//parallel data in and enable signal
		txd_o,//serial data out
		tre_o// ready to transmit flag
		);

  parameter // state difinition
     STA_IDLE = 0,
     STA_TRANS = 1,
     STA_FINISH = 2;
     
  input clk_i;
  input rst_i;
  input baud_clk_posedge;
  input [7:0] data_i;
  input wen_i;
  
  output txd_o;
  output tre_o;
  
  reg txd_o;
  reg tre_o;
   
  reg [7:0] tsr;//transmitting shift register
  reg [3:0] num_of_trans;
  
  reg [1:0] reg_sta;
 
  //the counter to count the clk in
  reg [3:0] count;
  reg count_c;//the carry of count
     
  always @(posedge clk_i or posedge rst_i)
  begin
    if(rst_i)
    begin
      tsr          <= 8'b0;
      txd_o        <= 1'b1;
      tre_o        <= 1'b1;
      num_of_trans <= 4'b0;
      count_c      <= 1'b0;
      count        <= 4'b0;
      reg_sta      <= STA_IDLE;
    end
    else begin
		if(baud_clk_posedge)
			case(reg_sta)
			STA_IDLE:
			begin
			  num_of_trans    <= 4'd0;
			  count           <= 4'd0;
			  count_c         <= 1'b0;
			  if(wen_i)
			  begin
				 tsr           <= data_i;
				 tre_o         <= 1'b0;
				 txd_o         <= 1'b0;// transmit the start bit 
				 reg_sta       <= STA_TRANS;
			  end
			  else 
				 reg_sta       <= STA_IDLE;
			end
			STA_TRANS:
			begin
			  {count_c,count} <= count + 1;
			  
			  if(count_c)
			  begin
				 if(num_of_trans <=4'd8)
				 begin
					//note ,when num_of_trans==8 ,we transmit the stop bit
					tsr          <= {1'b1,tsr[7:1]};
					txd_o        <= tsr[0];
					num_of_trans <= num_of_trans+1;
					reg_sta      <= STA_TRANS;
				 end
				 else begin
					txd_o        <= 1'b1;
					tre_o        <= 1'b1;
					reg_sta      <= STA_IDLE;
				 end
			  end
			end
			endcase
    end
  end
  
endmodule
