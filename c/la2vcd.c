/* Convert VeriFla captures to VCD */
/* Al Williams */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libserialport.h>  // From SIGROK -- need newer version than Ubuntu provides :(
// Look at https://sigrok.org/wiki/Libserialport
#include <ctype.h>
#include <unistd.h>
#include <time.h>
#include <stdint.h>

#define USERCMD_RESET 0
#define USERCMD_RUN 1

#define BAUD 9600

/*
Some basic terms:
Each capture has a certain number of capture bytes and a certain number of repeat bytes.
A complete set of capture bytes and the associated repeat bytes are a line
 */


void help()
{
  fprintf(stderr,"Usage: la2vcd [-B] [-W] [-F frequency] [-T timescale] -b baud, -t trigger_pos -c cap_width, -r repeat_width, -n samples -o vcd_file port_name\n");
  fprintf(stderr,"You need all the lower case options, although baud will default to 9600\n");
  fprintf(stderr,"-B output only bytes of capture\n-W output only words (default is both bytes and words)\n");
  fprintf(stderr,"-F sets frequency in MHz (e.g., -F 250).\n"
	  "Or you can set the timescale (e.g, -T 1ns) with -T. Note the timescale should be twice the clock frequency. Default to 1nS and you do your own math.\n");
  fprintf(stderr,"Al Williams al.williams@awce.com\n");
  exit(1);
}

// Convert a word to a number of bits
char *binary(uint64_t v, unsigned int bits)
{
  static char buffer[65];
  char *p=buffer+sizeof(buffer)-1;
  memset(buffer,'0',sizeof(buffer));
  *p--='\0';
  while (v)
    {
      *p--=(v&1)?'1':'0';
      v=v>>1;
    }
  return buffer+sizeof(buffer)-1-bits;  // note this is static with all that implies
}

  
// Get a capture from the buffer with a certain width starting at a particular address
uint64_t getbin(unsigned width, unsigned char *buf, unsigned base)
{
  uint64_t v=0;
  int j;
  for (j=0;j<width;j++) v=v*0x100+buf[base+j];
  return v;
}

// Read a line -- that is, capture and repeat count
void getbline(unsigned w1, unsigned w2, char *buf, unsigned base, uint64_t *v1, uint64_t *v2 )
{
  
      *v1=getbin(w1,buf,base+w2);
      *v2=getbin(w2,buf,base);
}

// Are we going to emit bytes, the whole thing, or both (3)
int bflag=3; // bytes=1, words=2


// Write a VCD output for a line
void writeline(FILE *f,uint64_t *t,uint64_t rpt, uint64_t data, int trigger, int capwidth)
{
  unsigned int i;
  unsigned int j;
  for (j=0;j<rpt;j++)
    {
      fprintf(f,"#%lu\n1!\n",*t);  // always do clock
      if (j==0)  // only have to do the first data point for the change block
	{
	  if (bflag&2) fprintf(f,"b%s # \n", binary(data,capwidth*8));
	  if (bflag&1) for (i=0;i<capwidth;i++) fprintf(f,"b%s %c \n",binary(data>>(8*i)&0xFF,8),'&'+i);
	  if (trigger)
	    fprintf(f,"1^\n");
	}
      fprintf(f,"#%lu\n0!\n",*t+1); // always trim up the clock

      *t+=2;
    }
}


// We can only handle 64 bit integers
void sizerr(const char *msg)
{
  fprintf(stderr,"Error: %s exceeds 64 bits\n",msg);
  exit(9);
}

  
  
  

int main(int argc, char *argv[])
{
  struct sp_port *port;
  int err;
  unsigned i;
  int copt;
  int baud=BAUD;
  unsigned int capwidth=0;
  unsigned int repwidth=0;
  unsigned int caplength=0;
  unsigned int count;
  unsigned int trigpos=0;
  char *vcdfile=NULL;
  char *timescale="1ns";
  float freq=-1;
  
  unsigned char *workbuf;
  FILE *vfile;
  time_t rawtime;
  struct tm * timedata;
  int debugging=0;  // undocumented ;-)
   
  
  
  if (argc<2)
    {
      help();
    }
  
  // process command line
  while ((copt=getopt(argc,argv,"DF:T:BWb:c:r:n:o:t:")) != -1)
    switch (copt)
      {
      case 'D':
	debugging=1;  // undocumented debug flag
	break;
      case 'T':
	timescale=optarg;   // set timescale
	break;
      case 'F':   // or set frequency
	freq=atof(optarg);
	freq=1.0/(freq*.000002);  // double plus microseconds to picoseconds
	break;
	
      case 'B':   // bytes only
	bflag=1;
	break;
      case 'W':   // whole capture only
	bflag=2;
	break;
	
      case 'b':   // baud rate
	baud=atoi(optarg);
	break;
      case 'c':   // set capture width in bytes
	capwidth=atoi(optarg);
	if (capwidth>sizeof(uint64_t)) sizerr("Capture width");
	break;
      case 'r':  // set repeat count in bytes
	repwidth=atoi(optarg);
	if (repwidth>sizeof(uint64_t)) sizerr("Replacement width");
	break;
      case 'n':   // set number of capture lines 
	caplength=atoi(optarg);
	break;
      case 'o':  // VCD output file
	vcdfile=optarg;
	break;
      case 't':   // set trigger position (lines)
	trigpos=atoi(optarg);
	break;
	
      default:
      case '?':
	help();
	break;
      }
  
  // figure out how many bytes we have
  count=(capwidth+repwidth)*caplength;
  if (count<=0)
    {
      fprintf(stderr,"You must specificy the number of bytes in the capture (-c),\n"
	      "the number of repeat count bytes in the capture (-r),\n"
	      "and the total number of capture samples (-n)\n");
      exit(3);
    }

  // make our buffer
  workbuf=(char *)malloc(count);
  if (!workbuf)
    {
      perror("Out of memory");
      exit(4);
    }
  
  // open the vcd file
  if (vcdfile)
    vfile=fopen(vcdfile,"w");
  else
    vfile=stdout;
  if (!vfile)
    {
      perror(vcdfile);
      exit(6);
    }
  
  // Serial port	
  err=sp_get_port_by_name(argv[optind],&port);
  if (err==SP_OK)
    err=sp_open(port,SP_MODE_READ_WRITE);
  if (err!=SP_OK)
    {
      fprintf(stderr,"Can't open port %s\n",argv[1]);
      exit(2);
    }
  sp_set_baudrate(port,BAUD); 
  // write reset
  i=USERCMD_RESET;
  sp_blocking_write(port,&i,1,100);
  // write run
  i=USERCMD_RUN;
  sp_blocking_write(port,&i,1,100);
  // read data (note data is backwards!)
  for (i=0;i<count;i++)  
    {
      int waiting;
      int c;
      do 
	{
	  waiting=sp_input_waiting(port);
	} while (waiting<=0);
      sp_nonblocking_read(port,(void *)&c,1);
      workbuf[(count-1)-i]=c;
    }
  sp_close(port);

  if (debugging)
    {
      int q;
      FILE *dfile=fopen("debug.txt","w");
      for (q=0;q<count;q+=3)
	{
	  // only works for specific format -c 2 -r 1
	  fprintf(dfile,"%02X: %02X %02X %02X\n",q/3,workbuf[q],workbuf[q+1],workbuf[q+2]);
	}
      fclose(dfile);
    }
  
  fprintf(stderr,"Writing vcd file\n");
  // produce header
  fprintf(vfile,"$version la2vcd 0.1 $end\n");
  
  time(&rawtime);
  timedata=localtime(&rawtime);
  fprintf(vfile,"$date %s $end\n",asctime(timedata));
  fprintf(vfile,"$timescale ");
  if (freq!=-1) fprintf(vfile,"%.0fps",freq);
  if (freq==-1) fprintf(vfile," %s",timescale);
  fprintf(vfile," $end\n");
  // send data definition
  fprintf(vfile,"$scope module CAPTURE $end\n");
  // Need to have a definition file or something for this but for now...
  fprintf(vfile,"$var wire 1 ! clk $end\n");
  if (bflag&2) fprintf(vfile,"$var wire %u # capdata $end\n",capwidth*8);
  fprintf(vfile,"$var wire 1 ^ triggered $end\n");
  if (bflag&1) for (i=0;i<capwidth;i++) fprintf(vfile,"$var wire 8 %c capbyte%u $end\n",'&'+i,i);
  
  fprintf(vfile,"$upscope $end\n");
  fprintf(vfile,"$enddefinitions $end\n");
  // Now we are ready to go  
  uint64_t  t=0;
  unsigned linewidth=capwidth+repwidth;
  uint64_t rct=0;
  uint64_t data=0;
  unsigned j;
  // Initialize variables
  fprintf(vfile,"$dumpvars\n0!\n0^\n");
  if (bflag&2) fprintf(vfile,"bx #\n");
  if (bflag&1) for (i=0;i<capwidth;i++) fprintf(vfile,"bx %c\n",'&'+i);
  fprintf(vfile," $end\n");
  uint64_t tail0,tail;
  // get the queue tail
  getbline(capwidth,repwidth,workbuf,(caplength-1)*linewidth,&tail,&rct); // rct not used here
  tail0=tail++;  // point to oldest part of buffer
  while (tail!=trigpos)
    {
      // output oldest part of buffer
      getbline(capwidth,repwidth,workbuf,tail*linewidth,&data,&rct);
      if (rct==0) break;
      writeline(vfile,&t,rct,data,0,capwidth);
      tail++;
    }
  // now go back and do the rest of the buffer
  tail=0;
  while (tail<=tail0)
    {
      // output newer part of buffer
      getbline(capwidth,repwidth,workbuf,tail*linewidth,&data,&rct);
      if (rct==0) break;
      writeline(vfile,&t,rct,data,0,capwidth);
      tail++;
    }
  // now do the trigger and the rest
  for (i=trigpos;i<caplength-1;i++)
    {
      getbline(capwidth,repwidth,workbuf,i*linewidth,&data,&rct);
      if (rct==0) break;
      writeline(vfile,&t,rct,data,i==trigpos,capwidth);
    }
  
  // close up shop and we are out of here
  if (vfile != stdout) fclose(vfile);
  if (workbuf) free(workbuf);
}
