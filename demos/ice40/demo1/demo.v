`default_nettype none
module top(input clk, output LED1, output LED2, output LED3,
	   output LED4, output LED5, output RS232_Tx, input RS232_Rx);
   reg [16:0] 	  count=0;
   wire 	  iclk;
   wire 		lareset;
   reg 			por=1;
   reg                  pordone=0;


// Generate a low sync edge on power up
// If you have a user reset you could and/or it in the following assign
   assign lareset=por;
   
   always @(posedge clk)
     if (pordone==1'b0)
       if (por==1'b1)
	 begin
	    por<=1'b0;
	 end
       else
	 begin
	    por<=1'b1;
	    pordone<=1'b1;
	 end

   
   
   assign iclk=count[16];

   reg [7:0] 	  subcount=0;
   
   
   
	  
   assign LED1=subcount[3];
   assign LED2=subcount[4];
   assign LED3=subcount[5];
   assign LED4=subcount[6];
   assign LED5=subcount[7];

   

   
   

   reg [7:0] 	  testit=8'haa;
   always @(posedge clk) 
     begin
	if (count[2])
  	   if (testit==8'haa) testit<=8'h55;
 	   else testit<=8'haa;
     end


   
   // logic analyzer
   top_of_verifla verifla(.clk(clk),.cqual(1'b1),.rst_l(lareset), .sys_run(1'b0),
			  .data_in({testit,count[8:1]}),
			  .uart_XMIT_dataH(RS232_Tx),
			  .uart_REC_dataH(RS232_Rx));
   
     
   always @(posedge clk) count<={ 0, count[15:0]} +1;
   
   always @(posedge clk) 
     begin
	if (iclk)
	  begin
	     subcount<=subcount+1;
	  end
     end
   
   

endmodule // top
