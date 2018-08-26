`default_nettype none
module top(input clk, output LED1, output LED2, output LED3,
	   output LED4, output LED5, output RS232_Tx, input RS232_Rx);

   wire 	  iclk;
   reg 		  BYPASS=0, RESETB=1;
   wire resetp;
   
   
   reg [15:0] 	  count=0;
   reg [7:0] 	  ctimer=0;
 	  
   reg 		  [3:0] laresetct=0;
   wire 		lareset;
		

   assign lareset = (laresetct==4'b0000 || laresetct==4'b1111);


   SB_PLL40_CORE #(
		   
         .FEEDBACK_PATH("PHASE_AND_DELAY"),
        .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
        .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
        .PLLOUT_SELECT("SHIFTREG_0deg"),
        .SHIFTREG_DIV_MODE(1'b0),
        .FDA_FEEDBACK(4'b0000),
        .FDA_RELATIVE(4'b0000),
        .DIVR(4'b0000),    // frequency divide 0+1 =1
        .DIVF(7'b0000011), // frequency multiplier = 3+1 = 4  (48 Mhz)
        .DIVQ(3'b000),     // not used in non-simple?
        .FILTER_RANGE(3'b001))  // range 0-6 but not sure why?
   pll(
       .REFERENCECLK(clk),
       .PLLOUTGLOBAL(iclk),
       .BYPASS(BYPASS),
       .RESETB(RESETB),
       .LOCK(resetp));
   


 
   
   
	  

   
   // logic analyzer
// Since the state machine can only change when count==0, using the clock qualifer
// lets us skip so many repeating values
   top_of_verifla verifla(.clk(iclk),.cqual(count==0),.rst_l(lareset), .sys_run(1'b0),
			  .data_in({ctimer,runs,led_1,state}),   
			  .uart_XMIT_dataH(RS232_Tx),
			  .uart_REC_dataH(RS232_Rx),.armed(armed),.triggered(triggered));
   
// generate POR reset for logic analyzer
   always @(posedge iclk) if (resetp && laresetct!=4'b1111) laresetct<=laresetct+4'b0001;


     
/*
 Simple state machine
 
  WAIT0 - wait for timer to expire, turn on LED1, set timer=100 if runs<10 goto WAIT1 else goto WAIT2
  WAIT1 - wait for timer to expire, LED1=off, timer=250, runs++, goto WAIT0
  WAIT2 - wait for timer to expire, timer=250, runs=0, goto WAIT0
 */

   

   reg [2:0] state=1;
   reg 	     led_1;
   reg [3:0] runs=0;

   wire 		armed;
   wire 		triggered;

   assign LED1=led_1;
   assign LED2=armed;
   assign LED3=triggered;
   assign LED4=count[15];
   assign LED5=lareset;

   always @(posedge iclk)
     begin
	count<=count+1;
	if (ctimer!=0 && count==0) ctimer<=ctimer-1;
	case (state)
	     3'b001:
	       begin
		  if (ctimer==0)
		    begin
		       led_1<=1'b1;
		       ctimer<=100;
		       state<=runs==10?3'b100:3'b010;
		    end
	       end
   	     3'b010:
	       begin
		  if (ctimer==0)
		    begin
		       led_1<=1'b0;
		       ctimer<=250;
		       runs<=runs+1;
		       state<=3'b001;
		    end
	       end
	  3'b100:
	    begin
	       if (ctimer==0)
		 begin
		    ctimer<=250;
		    runs<=0;
		    state<=3'b001;
		 end
	    end
	  default:
	    begin
	       state<=1;  // never gets here we hope
	    end
	endcase // case (state)
     end
   

endmodule // top
