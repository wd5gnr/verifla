/* This is the Verifla configuration file 
   You should have this in your work directory for each project
   You should have the verifla library under your work directory
   either as a symlink or a copy
   The library code will look for ../verifla_config.v (this file)
*/

// ********* TIMING and COMMUNICATONS
parameter CLOCK_FREQUENCY = 48_000_000;
// If CLOCK_FREQUENCY < 50 MHz then BAUDRATE must be < 115200 bps (for example 9600).
parameter BAUDRATE = 9600;
// The Baud Counter Size must have enough bits or more to hold this constant
parameter T2_div_T1_div_2 = CLOCK_FREQUENCY / (BAUDRATE * 16 * 2);
// Assert: BAUD_COUNTER_SIZE >= log2(T2_div_T1_div_2) bits
parameter BAUD_COUNTER_SIZE = 15;

// ********* Data Setup
// Number of data inputs (must be a multile of 8)
parameter LA_DATA_INPUT_WORDLEN_BITS=16;

// ******** Trigger
// Your data & LA_TRIGGER_MASK must equal LA_TRIGGER_VALUE to start a complete capture
parameter LA_TRIGGER_VALUE=16'h0004, LA_TRIGGER_MASK=16'h0007;

// To help store more data, the LA counts how many samples are identical
// The next parameter is the size of the repeat count. Must be a multiple of 8 bits
// If the count overflows you just get another sample that starts counting again.
parameter LA_IDENTICAL_SAMPLES_BITS=8;

// ******** Memory Setup
// Pick how many address bits you'll use and the first and last address
// The first address will almost always be 0 and the last will almost always
// be 2^bits-1. For example, 8,0,255 or 10,0,1023
parameter LA_MEM_ADDRESS_BITS=8; 
parameter LA_MEM_FIRST_ADDR=0,
          LA_MEM_LAST_ADDR=255;
// The memory is divided into two regions. The first region is a circular buffer
// that stores all data before the trigger. Then the trigger occurs and is stored
// at a fixed address. All the data after the trigger occurs after that. The last word
// of memory is reserved for a tail pointer to the circular buffer
// For example, if the memory size is 1K
// You might set the next parameter to 500. This would store up to 500
// lines of data before the trigger (because of the repeat count, this could be more than
// 500 samples). It could store less, because the buffer could be not full when
// the trigger occurs. Then the trigger word will be at address 500 and the remaining
// samples will follow. The last word of the memory will indicate where the last write
// in the buffer was (thus, the next address is the oldest data in the buffer).
// TLDR: What address do I use to start storing the trigger and subsequent data
parameter LA_TRIGGER_MATCH_MEM_ADDR=129;
// The LA will continue to capture after the trigger until a certain number of samples
// arrive or memory is full. Because of the repeat count, a low number here could
// just cause the sample to stop on the trigger. For example, suppose the input
// will not change for 50 cycles after the trigger and you set this to 20 samples.
// You would just get a repeat count of 20 on the trigger word.
// If you like, set this value to something very large and you'll better use memory
// Be sure the number of bits is enough to hold the count
parameter LA_MAX_SAMPLES_AFTER_TRIGGER_BITS=16;  
parameter    LA_MAX_SAMPLES_AFTER_TRIGGER=30000;
// Because the circular buffer and the post trigger buffer may not be full
// You may want to let the LA write a known value to the buffer before starting
// The tools are good about hiding these data "holes" from you, though

// Set this to 1 if you want to fill the buffer with a marker value
parameter LA_MEM_CLEAN_BEFORE_RUN=1;
parameter LA_MEM_EMPTY_SLOT=8'hEE;

// ********** Below this you shouldn't have to change anything

parameter LA_MEM_WORDLEN_BITS=(LA_DATA_INPUT_WORDLEN_BITS+LA_IDENTICAL_SAMPLES_BITS); 
parameter LA_MEM_WORDLEN_OCTETS=((LA_MEM_WORDLEN_BITS+7)/8);
parameter LA_BT_QUEUE_TAIL_ADDRESS=LA_MEM_LAST_ADDR;
// constraint: (LA_MEM_FIRST_ADDR + 4) <= LA_TRIGGER_MATCH_MEM_ADDR <= (LA_MEM_LAST_ADDR - 4)
//parameter LA_TRIGGER_MATCH_MEM_ADDR=((1 << LA_MEM_ADDRESS_BITS) >> 3),

parameter  LA_MEM_LAST_ADDR_BEFORE_TRIGGER=(LA_TRIGGER_MATCH_MEM_ADDR-1);

// Identical samples
parameter LA_MAX_IDENTICAL_SAMPLES=((1 << LA_IDENTICAL_SAMPLES_BITS) - 2);  


