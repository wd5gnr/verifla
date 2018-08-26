# Verifla
This is a fork of OpenVerifla (https://opencores.org/project/openverifla) that tries to do a few things:

1) Document some of the settings a bit better
2) Fix a bug where samples that changed on one clock were not handled properly
3) Add synchronous memory that is easier for some tools to infer
4) Some minor cleanups and plans for enhancments
5) C tool to read output and generate VCD directly (see C directory for build instructions)
6) Adds clock enable/qualifer
7) Adds armed and trigger outputs

The PDF attached has some good information on it. However, a few things to note:

1) Do not set Run to 1 in your code unless your trigger is infrequent. If data constantly
spews out of the FPGA, the JAVA code can not sync to it.

2) There are some strange unsquashed bugs. For example, on the Lattice iCe40
with Icestorm tools (at least) setting memory to 256 bytes and the trigger position to
128 causes a hang. Trigger positions at 127 and 129 are fine.

# Possible Enhancements
1) Uart clock vs Sample clock (Uart clock >> Sample clock)
2) Clock Enable for sample clock (done)
3) Change post trigger samples to do post trigger memory words (or document to set huge #)
4) Java: Pick up Verilog file from template

# Quick Start
1. Link or copy the verifla directory (the one under verilog) to your project directory
2. Copy config_verifla.v.template to your working directory and rename it to config_verifla.v
3. Make sure your Verilog tool will look in the verifla directory as a library
4. Make sure the search path for includes will look in your project directory first
5. Edit config_verifla.v in your project directory to se clock speed, baud rate, memory size, etc.
6. Write your verilog in the project directory.
7. Create a top_of_verifla module. Here are the signals:
* clk - Clock
* cqual - Qualifier for data capture clock (UART and other things use clk alone). If you don't want a qualifer, just set to 1'b1. IMPORTANT: You do need to set this to something.
* rst_l - Active low reset.
* sys_run - High to arm logic analyzer. If you only want to arm from the PC, set to 1'b0.
* data_in - Your inputs. Group together like {led3, led2, led1, led0, count[3:0]}.
* uart_XMIT_dataH - Your RS232 transmit line
* uart_REC_dataH - Your RS232 receive line
* armed - digital output showing LA is armed
* triggered - digital output showing LA is triggered
8. Once running you can use the original Java program to create a .v file you will need to simulate or the C program (la2vcd) to create a .vcd you can read using a waveform viewer (like GTKWave)

# Notes about using GTKWave
The C program creates a simple dump that has the entire capture data and also each byte captured. You can supress the bytes (-W) or the aggregate (-B) if you like. However, you really want to have the signals broken back out like they are in your code.

Suppose you have 16-bits of data like this:
   counter8[7:0], led0, state[6:0]

It is easy to add the capdata[15:0] data to GTKWave. Then expand it into bits. Select the
counter8 bits and press Combine Down on the Edit menu (or Combine Up if you are reversed endian).
This will prompt you for a name so enter "counter8" and press OK. Now you'll have a counter 8 signal. Repeat for state. For the led0 signal, you can create an alias.

Of course, this is painful to set up every time so use Write Save File on the File menu. This will save the layout for next time you load a VCD with the same format.

