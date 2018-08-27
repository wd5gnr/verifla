`default_nettype none
module top(input clk, output LED1, output LED2, output LED3,
	   output LED4, output LED5, output RS232_Tx, input RS232_Rx);

   
   reg [15:0] 	  count=0;
   reg [7:0] 	  ctimer=0;
 	  
   reg 		  [3:0] laresetct=0;
   wire 		lareset;
		

   assign lareset = (laresetct==4'b0000 || laresetct==4'b1111);



   
   // logic analyzer
// Since the state machine can only change when count==0, using the clock qualifer
// lets us skip so many repeating values
   top_of_verifla verifla(.clk(clk),.cqual(1'b1),.rst_l(lareset), .sys_run(1'b0),
			  .data_in({ctimer,6'b0,state}),   
			  .uart_XMIT_dataH(RS232_Tx),
			  .uart_REC_dataH(RS232_Rx));
   
   
// generate POR reset for logic analyzer
   always @(posedge clk) if (laresetct!=4'b1111) laresetct<=laresetct+4'b0001;


     
/*
 Simple state machine
 
  CW - n=n+1,  led-on ctimer=250, >CWAIT 
  CWAIT - wait for timer, if n==3 >CCW else >CW
  CCW - n=n-1, led-on ctimer=250, CCWAIT
  CCWAIT - wait for timer, if n==0 >CW else CCW

 */

// dense encoding
   localparam CW = 2'b00;
   localparam CWAIT = 2'b01;
   localparam CCW = 2'b10;
   localparam CCWAIT = 2'b11;
   

   reg [1:0] state=CW;
   reg [3:0] leds=1;
   reg 	     blink=0;
   



   assign LED1=leds[0];
   assign LED2=leds[1];
   assign LED3=leds[2];
   assign LED4=leds[3];
   assign LED5=blink;
   

    


   always @(posedge clk)
     begin
	count<=count+1;
	if (ctimer!=0 && count==0) ctimer<=ctimer-1;
	case (state)
	     CW:
	       begin
		  leds={leds[2:0],1'b0};
		  ctimer<=250;
		  blink<=~blink;
		  state<=CWAIT;
	       end
   	     CWAIT:
	       begin
		  if (ctimer==0)
		    begin
		       state<=leds[3]?CCW:CW;
		    end
	       end
	  CCW:
	    begin
	       leds={1'b0,leds[3:1]};
	       blink<=~blink;
	       ctimer<=250;
	       state=CCWAIT;
	    end
	  CCWAIT:
	    begin
	       if (ctimer==0)
		 begin
		    state<=leds[0]?CW:CCW;
		 end
	    end
	  default:
	    begin
	       state<=CW;  // never gets here we hope
	    end
	endcase // case (state)
     end
   

endmodule // top
