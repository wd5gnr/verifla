This is a simple utility to capture data from openverifla and dump it directly to a vcd.

# Compile
Should compile with any normal C compiler where libserialport is available (get from Sigrok).
You do need a recent version of libserialport -- the one currently in Ubunut repos will not work.

   gcc -o la2vcd la2vcd.c -lserialport

# Usage
Usage: la2vcd [-V] [-B] [-W] [-F frequency] [-T timescale] -b baud, -t trigger_pos -c cap_width, -r repeat_width, -n samples -o vcd_file port_name

You need all the lower case options, although baud will default to 9600

* -V show progress on console

* -B output only bytes of capture

* -W output only words (default is both bytes and words)

* -F sets frequency in MHz (e.g., -F 250).

Or you can set the timescale (e.g, -T 1ns) with -T. Note the timescale should be twice the clock frequency. Default to 1nS and you do your own math.

Great idea to build a script with all the "standard" settings for a project:

   #!/bin/bash

   exec la2vcd -W -F 50 -b 57600 -t 129 -c 3 -r 1 -n 256 -o "$1"

Just as an example.

Al Williams al.williams@awce.com
