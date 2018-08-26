/*
VeriFLA.java
License: GNU GPL

Revision history:
revistion date: 2018/07/20; author: Laurentiu Duca
- port of SerialPort jssc instead of rxtx
- redesign of memory contents implied modification in the java source
revision date: 2007/Sep/03;  author: Laurentiu Duca
- sendMonResetAndRun feature
- consider that the bt_queue_head_address is wrote at the end of the data capture.
- use HOUR_OF_DAY (0..23)

revision date: 2007/Jul/4; author: Laurentiu DUCA
- v01
*/

 
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.BufferedReader;
import java.util.Properties;
import java.util.Enumeration;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.StringTokenizer;

import jssc.SerialPort;
import jssc.SerialPortException;

public class VeriFLA extends Object {

	// Data members are declared at the end.

	/**
	 * Creates a new object.
	 *
	 */	
	public VeriFLA() {
		this.serialPort = null;
		this.properties = new Properties();
	}

	/**
	 * Attaches the given serial serialPort to the device object.
	 * The method will try to open the serialPort.
	 */
	public boolean attach(String portName) {
		serialPort = new SerialPort(portName);
		try {
			int baudrate=Integer.parseInt(strBaudRate);
				//strBaudRate.equals("115200")?SerialPort.BAUDRATE_115200:
				//strBaudRate.equals("38400")?SerialPort.BAUDRATE_38400:SerialPort.BAUDRATE_9600;
			serialPort.openPort();//Open serial port
			serialPort.setParams(baudrate, 
                             SerialPort.DATABITS_8,
                             SerialPort.STOPBITS_1,
                             SerialPort.PARITY_NONE);
			//Set params. Also you can set params by this string: serialPort.setParams(9600, 8, 1, 0);
			//serialPort.writeBytes("This is a test string".getBytes());//Write data to port
		} catch (SerialPortException ex) {
			ex.printStackTrace(System.out);
			return false;
		}

		return true;
	}
	
	/**
	 * Detaches the currently attached serialPort, if one exists.
	 * This will close the serial port.
	 *
	 */
	public void detach() {
		if (serialPort != null) {
			try {
				serialPort.closePort();
			} catch (SerialPortException ex) {
				ex.printStackTrace(System.out);
			}
		}
	}
		
	public void run() throws IOException, SerialPortException {
		byte rawByte[]=new byte[1];

		if(sendMonResetAndRun == 1) {
			// Send USERCMD_RESET command
			rawByte[0]=USERCMD_RESET;
			System.out.println("Sending USERCMD_RESET command");
			serialPort.writeBytes(rawByte);
			System.out.println("Done sending USERCMD_RESET command.");				
						
			// Send USERCMD_RUN command
			rawByte[0]=USERCMD_RUN;
			System.out.println("Sending USERCMD_RUN command");
			serialPort.writeBytes(rawByte);
			System.out.println("Done sending USERCMD_RUN command.");		
		}
		
		// Read Captured data
		System.out.println("Waiting for data capture:");
		int i,j,ret;
		rawByte = new byte[memWords * octetsPerWord];
		//rawByte = serialPort.readBytes(memWords * octetsPerWord);
		for(i=0; i<memWords; i++) {
			rawByte = serialPort.readBytes(octetsPerWord);
			for(j=0; j<octetsPerWord; j++) {
				//memoryLineBytes[memWords-1 - i][j]=rawByte[i*j];				
				memoryLineBytes[memWords-1 - i][j]=rawByte[j];
			}
		}
		System.out.println("Data receive end.");

		// Debug
		if(!debugVeriFLA)
			return;
		System.out.println("Received data:");
		for(i=0; i<memWords; i++) {
			System.out.printf("%03d: ", i);
			for(j=octetsPerWord-1; j>=0; j--)
				System.out.printf("%02x ", memoryLineBytes[i][j]);
			System.out.println();
		}

		//System.exit(1);
	}

	public void getCapturedData(String portName)
	{
		boolean found;
		found = attach(portName);
		if(!found) {
			System.out.println("Port " + portName + " not found.\n"+
				"\tPlease update the properties file.\n");
			System.exit(0);
		}		
		try {
			run();
		} catch (Exception ex) {
			ex.printStackTrace(System.out);
		}
		detach();				
	}
	
	public void saveCapturedData() throws IOException
	{
		// Create a new file with the name "capture_timestamp.v".
		String strTime=getTime();			
		String outputFileName, moduleName;
		moduleName="capture_"+strTime;
		outputFileName = moduleName+".v";
		File outputFile = new File(outputFileName);
		if (!outputFile.createNewFile()) {
			System.out.println("Error: Can not create file: " + outputFileName);
			System.exit(-1);
		}	
		OutputStream stream = new FileOutputStream(outputFile);
		
		
		// Write the timescale directive.
		String strLine;
		int i,j,k;
		strLine = "`timescale " + strTimescaleUnit + " / " + strTimescalePrecision + "\n\n";
		stream.write(strLine.getBytes());		
		
		
		// Write the module name and output params.
		strLine = "module " + moduleName + "(clk_of_verifla, la_trigger_matched, ";
		for (i = 0; i < signalGroups; i++) {
			strLine += groupName[i];
			if(i != (signalGroups - 1))
				strLine += ", ";
		}
		strLine += ", memory_line_id";
		strLine += ");\n\n";
		stream.write(strLine.getBytes());		
		
		
		// Write the declaration of signals
		strLine = "output clk_of_verifla;\n" + "output la_trigger_matched;\n" + "output ["+(memWords/4)+":0] memory_line_id;\n";
		stream.write(strLine.getBytes());
		for (k = 0; k < 2; k++) {
			for (i = 0; i < signalGroups; i++) {
				if(k == 0)
					strLine = "output ";
				else
					strLine = "reg ";
				if(groupSize[i] > 1) {
					if(groupEndian[i] != 0)
						strLine += "[0:"+(groupSize[i]-1)+"] ";
					else
						strLine += "["+(groupSize[i]-1)+":0] ";
				}
				strLine += groupName[i] + ";\n";
				stream.write(strLine.getBytes());	
			}
		}
		strLine =
			"reg ["+(memWords/4)+":0] memory_line_id;\n" +
			"reg la_trigger_matched;\n" +
			"reg clk_of_verifla;" + "\n\n" +
			"parameter PERIOD = " + clockPeriod + ";" + "\n";
		stream.write(strLine.getBytes());
		
		
		// Write the clock task.
		strLine =	 
		    "initial    // Clock process for clk_of_verifla" + "\n" +
		    "begin" + "\n" +
		    "    forever" + "\n" +
		    "    begin" + "\n" +
		    "        clk_of_verifla = 1'b0;" + "\n" +
		    "        #("+ (int)(clockPeriod / 2) + "); clk_of_verifla = 1'b1;" + "\n" +
		    "        #("+ (int)(clockPeriod / 2) + ");" + "\n" +
		    "    end" + "\n" +
		    "end" + "\n\n" ;
		stream.write(strLine.getBytes());		

		
		// Write captured data
		strLine = "initial begin\n";
		strLine += "#("+ (int)(clockPeriod / 2) + ");\n";
		strLine += "la_trigger_matched = 0;\n";
		stream.write(strLine.getBytes());
		
		// Compute the name of the signals
		String signalsToken;
		signalsToken = "{";
		for (i = signalGroups-1; i >= 0 ; i--) {
			signalsToken += groupName[i];
			if (i > 0)
				signalsToken += ",";
		}
		signalsToken += "} = ";
						
		// Write name of the signals, values and delays in the verilog file.
		String strWord;
		int currentTime=(clockPeriod / 2), delay;
		
		// compute the oldest wrote-info before trigger event
		int bt_queue_head_address=0, bt_queue_tail_address=0;
		// the word at address (memWords-1) represents bt_queue_tail_address.
		for(j = 0; j < (octetsPerWord-1); j++) {
			bt_queue_tail_address += ((0x000000FF) & (int) memoryLineBytes[memWords-1][j]) << (8*j);
		}
		System.out.println("bt_queue_tail_address=" + bt_queue_tail_address);
		// Find the first <efffective capture memory word>
		// before the trigger event (not an <emtpy-slot> memory word).
		if(bt_queue_tail_address == (triggerMatchMemAddr - 1))
			bt_queue_head_address = 0;
		else
			bt_queue_head_address = bt_queue_tail_address + 1;
		boolean before_trigger=true;
		boolean foundAnEffectiveCaptureWord=false, wentBack=false;
		i = bt_queue_head_address;
		do
		{
			for(j = 0; j < (octetsPerWord-1); j++) {
				if(memoryLineBytes[i][j] != 0)
					foundAnEffectiveCaptureWord = true;
			}
			if(foundAnEffectiveCaptureWord)
				break;
			i++;
			if(i >= triggerMatchMemAddr)
				if(!foundAnEffectiveCaptureWord && !wentBack) {
					i = 0;
					wentBack = true;
				}
		} while (i <= triggerMatchMemAddr);
		if(!foundAnEffectiveCaptureWord)
			fatalError("Could not find the first efffective capture before trigger match");
		if(i >= triggerMatchMemAddr)
			before_trigger=false;
		
		// Walk through the captured data and write it to capture.v	
		do {
			// Check if this is an empty line
			boolean allMemoryLineIsZero=true;
			for(j=octetsPerWord-1; j>=0; j--) {
				if(memoryLineBytes[i][j] != 0) {
					allMemoryLineIsZero = false;
					break;
				}			
			}
			if(allMemoryLineIsZero) {
				if(debugVeriFLA) {
					strLine = "// info: line "+i+" is empty.\n";
					System.out.println(strLine);
					stream.write(strLine.getBytes());
				}
			} else {
				// Write memory line index.
				strLine = "memory_line_id=" + i + ";\n";
				stream.write(strLine.getBytes());
				// Data capture
				strWord = totalSignals + "'b";
				for(j=octetsPerWord-1; j>=0; j--) {
					if((j * 8) < dataWordLenBits)
						for(k=7; k>=0; k--) {
							if((j*8+k) < totalSignals) {
								strWord += (memoryLineBytes[i][j] >> k) & 1;
							}
						}
				}
				strWord += ';';
				strLine = signalsToken + strWord + "\n";
				if(i == triggerMatchMemAddr)
					strLine += "la_trigger_matched = 1;\n";
				//strLine += "#" + clockPeriod + ";\n";
				// Write to file
				//System.out.println(strLine);
				stream.write(strLine.getBytes());


				// Time interval in which data is constant.
				delay=0;
				for(j = 0; j < octetsPerWord; j++) {
					if((j * 8) >= dataWordLenBits)
						delay += ((0x000000FF) & (int) memoryLineBytes[i][j]) << (8*j - dataWordLenBits);
				}
				currentTime += delay * clockPeriod;
				strLine = "#" + (delay * clockPeriod) + ";\n";
				// Write to file
				//System.out.println(strLine);
				stream.write(strLine.getBytes());
				// Also write the time stamp
				strLine = "// -------------  Current Time:  " + currentTime + "*(" + strTimescaleUnit + ") "+"\n";
				stream.write(strLine.getBytes());
			}
			
			// Compute the new value of i
			if(before_trigger) {
				i = (i+1) % triggerMatchMemAddr;
				if(i == bt_queue_head_address) {
					before_trigger = false;
					i = triggerMatchMemAddr;
				}
			}	
			else
				i = i + 1;
		} while (i < (memWords-1));
		
		strLine = "$stop;\nend\nendmodule\n";	
		stream.write(strLine.getBytes());	

		// Write raw memory information.		
		strLine = "/*\n"+STR_ORIGINAL_CAPTURE_DUMP+"\n";	
		for(i=0; i<memWords; i++) {
			strLine += "memory_line_id=" + i + ": ";
			for(j=octetsPerWord-1; j>=0; j--) {
				//strLine += "["+j+"]"+" " + Integer.toHexString(memoryLineBytes[i][j]) + " ";
				if((0x000000FF & (int) memoryLineBytes[i][j]) <= 0x0F)
					strLine += "0";
				strLine += Integer.toHexString(
					0x000000FF & (int) memoryLineBytes[i][j]).toUpperCase() + " ";
			}
			strLine += "\n";
		}
/*
		for(i=0; i<memWords; i++) {
			strLine = "";
			// Write the memory address of the word
			if(i <= 9)
				strLine += "0";
			strLine += i + " ";
			for(j=octetsPerWord-1; j>=0; j--) {
				if((0x000000FF & (int) memoryLineBytes[i][j]) <= 0x0F)
					strLine += "0";
				strLine += Integer.toHexString(
					0x000000FF & (int) memoryLineBytes[i][j]).toUpperCase() + " ";
			}
			strLine += "\n";
			stream.write(strLine.getBytes());	
		}
*/
		strLine += "*/\n";
		stream.write(strLine.getBytes());	
				
		stream.close();
		System.out.println("Job done. Please simulate " + outputFileName);
	}
	
	private void allocateMemory()
	{
		// Allocate memory
		int i,j;
		memoryLineBytes = new byte[memWords][];
		for(i=0; i<memWords; i++)
			memoryLineBytes[i] = new byte[octetsPerWord];
	}
/*	
	private void simGetCapturedData() 
	{	
		// Init memory.	
		int i,j;
		for(i=0; i < memWords; i++)
		{
			for(j=0; j < octetsPerWord; j++) {
					memoryLineBytes[i][j]=(byte) i;
			}
		}
	}
*/
	public void rebuildCapturedDataFromFile(String fileName) 
	{
		try {
			String line;
			File file;		
			file = new File(fileName);
			if (!file.isFile())
				fatalError("Error: File does not exist: " + fileName);
			BufferedReader br = new BufferedReader(new FileReader(file));
	
			boolean startOfMemory=false, allMemoryRead=false;
			int i=0, j=0, tNo;
			
			do {
				line = br.readLine();
				if (line == null)
					fatalError("File " + fileName + " got null line while reading.");
				//if(startOfMemory) {
					StringTokenizer st;
					st = new StringTokenizer(line," ");
					tNo= st.countTokens();
					if(tNo != (octetsPerWord+1))
						fatalError("File " + fileName + " tNo != 2: " + tNo + " != 2" + (octetsPerWord+1));
					st.nextToken();
					for(j=octetsPerWord-1; j>=0; j--) {
						memoryLineBytes[i][j] = (byte) Integer.parseInt(st.nextToken(), 16);
					}
					i++;
					if(i >= memWords)
						allMemoryRead = true;
				//}
				//else
				//if (line.startsWith(STR_ORIGINAL_CAPTURE_DUMP)) {
				//	startOfMemory=true;
				//	i = 0;
				//}
			} while (!allMemoryRead);
		} catch (Exception e) {
			e.printStackTrace();
			fatalError("rebuildCapturedDataFromFile exception");
		}
	}
	
	public void job(String propertiesFileName, String strRebuildFileName)
	{
		getProperties(propertiesFileName);
		allocateMemory();
		if(strRebuildFileName == null)
			getCapturedData(portName);
		else
			rebuildCapturedDataFromFile(strRebuildFileName);
		try {
			saveCapturedData();
		} catch (IOException e) {
			e.printStackTrace();
			fatalError("Error saving Captured Data");
		}
	}

	public static void fatalError(String errorName)
	{
		System.out.println("Fatal error: " + errorName);
		System.exit(-1);
	}
	
	public void getProperties(String fileName)
	{
		File f;
		f = new File(fileName);
		if (!f.isFile()) {
			System.out.println("Error: File does not exist: " + fileName);
			System.exit(-1);
		}
		
		InputStream stream;
		try {
			stream = new FileInputStream(f);
			try {
				properties.load(stream);
			} catch (IOException e) {
				fatalError("IOException " + fileName);
			} 
		} catch (FileNotFoundException e) {
			fatalError("FileNotFoundException "+ fileName);
		}

		String strVal;
		portName = properties.getProperty(NAME + ".portName");
		if(portName == null)
			fatalError("Properties: missing portName");
		strBaudRate = properties.getProperty(NAME + ".baudRate");
		if(strBaudRate == null)
			fatalError("Properties: missing baudRate");
		//if(!strBaudRate.equals("115200") && !strBaudRate.equals("38400") && !strBaudRate.equals("9600"))
			//fatalError("Invalid baudRate (must be 115200 or 38400 or 9600)");

		// time units
		strTimescaleUnit=properties.getProperty(NAME + ".timescaleUnit");
		strTimescalePrecision=properties.getProperty(NAME + ".timescalePrecision");
		if(strTimescaleUnit == null || strTimescalePrecision == null) 
			fatalError("Properties: Not found timescale - unit or precision");
		// clockPeriod
		strVal=properties.getProperty(NAME + ".clockPeriod");
		if(strVal != null)
			clockPeriod=Integer.parseInt(strVal);
		else
			fatalError("Properties: clockPeriod not found");					
			
		// User signals
		strVal=properties.getProperty(NAME + ".totalSignals");
		if(strVal != null)
			totalSignals=Integer.parseInt(strVal);
		else
			fatalError("Properties: endian not found");		
		// Groups of signals
		strVal=properties.getProperty(NAME + ".signalGroups");
		if(strVal != null)
			signalGroups=Integer.parseInt(strVal);
		else
			fatalError("Properties: signalGroups not found");
		groupName=new String[signalGroups];
		groupSize=new int[signalGroups];
		groupEndian=new int[signalGroups];
		int i;
		int sumOfSignals=0;
		for (i=0; i < signalGroups; i++)
		{
			String strGroupName, strGroupSize, strGroupEndian;
			strGroupName=properties.getProperty(NAME + ".groupName."+i);
			strGroupSize=properties.getProperty(NAME + ".groupSize."+i);
			strGroupEndian=properties.getProperty(NAME + ".groupEndian."+i);
			if(strGroupName == null || strGroupSize == null || strGroupEndian == null)
				fatalError("Properties: group " + i + " not found groupName or groupSize or groupEndian");
			else {
				groupName[i]=strGroupName;
				groupSize[i]=Integer.parseInt(strGroupSize);
				sumOfSignals += groupSize[i];
				groupEndian[i]=Integer.parseInt(strGroupEndian);
			}	
		}
		if(sumOfSignals != totalSignals)
			fatalError("Properties: totalSignals != sum of all group sizes: " + totalSignals + " != "+sumOfSignals);

		
		// Memory
		strVal=properties.getProperty(NAME + ".memWords");
		if(strVal != null)
			memWords=Integer.parseInt(strVal);
		else
			fatalError("Properties: memWords not found");
		strVal=properties.getProperty(NAME + ".dataWordLenBits");
		if(strVal != null)
			dataWordLenBits=Integer.parseInt(strVal);
		else
			fatalError("Properties: dataWordLenBits not found");
		if((dataWordLenBits % 8) != 0)
			fatalError("Properties: dataWordLenBits is not multiple of 8");
		strVal=properties.getProperty(NAME + ".clonesWordLenBits");
		if(strVal != null)
			clonesWordLenBits=Integer.parseInt(strVal);
		else
			fatalError("Properties: clonesWordLenBits not found");
		if((clonesWordLenBits % 8) != 0)
			fatalError("Properties: clonesWordLenBits is not multiple of 8");
		memWordLenBits = dataWordLenBits + clonesWordLenBits;
		// Compute sizes
		// octetsPerWord
		octetsPerWord = memWordLenBits / 8;
		if (memWordLenBits % 8 > 0)
			octetsPerWord++;
		totalmemoryDataBytes = memWords*octetsPerWord;
		// Trigger
		strVal=properties.getProperty(NAME + ".triggerMatchMemAddr");
		if(strVal != null)
			triggerMatchMemAddr=Integer.parseInt(strVal);
		else
			fatalError("Properties: triggerMatchMemAddr not found");
/*
		strVal=properties.getProperty(NAME + ".maxSamplesAfterTrigger");
		if(strVal != null)
			maxSamplesAfterTrigger=Integer.parseInt(strVal);
		else
			fatalError("Properties: maxSamplesAfterTrigger not found");

		// triggerLastValue
		strVal=properties.getProperty(NAME + ".triggerLastValue");
		if(strVal != null) {
			StringTokenizer st;
			int j, tNo;
			st = new StringTokenizer(strVal," ");
			tNo= st.countTokens();
			if(tNo != octetsPerWord)
				fatalError("triggerLastValue " + " tNo != octetsPerWord: " + tNo + " != " + octetsPerWord);	
			triggerLastValue = new int[octetsPerWord];
			for(j=octetsPerWord-1; j>=0; j--) {
				triggerLastValue[j] = (byte) Integer.parseInt(st.nextToken(), 16);
			}
		}
		else
			fatalError("Properties: triggerLastValue not found");
*/			
	}

	public String getTime()
	{
		Calendar calendar=new GregorianCalendar();
		String strTime;
		int field;
		strTime = "" + calendar.get(Calendar.YEAR);
		field = 1 + calendar.get(Calendar.MONTH);
		if(field < 10)
			strTime += "0";
		strTime += field;
		if(calendar.get(Calendar.DAY_OF_MONTH) < 10)
			strTime += "0";
		strTime += calendar.get(Calendar.DAY_OF_MONTH) + "_" ;
		if(calendar.get(Calendar.HOUR_OF_DAY) < 10)
			strTime += "0";
		strTime += calendar.get(Calendar.HOUR_OF_DAY);
		if(calendar.get(Calendar.MINUTE) < 10)
			strTime += "0";
		strTime += calendar.get(Calendar.MINUTE) + "_";
		if(calendar.get(Calendar.SECOND) < 10)
			strTime += "0";
		strTime += calendar.get(Calendar.SECOND) ;
		System.out.println("date and time: "+strTime);
		return strTime;		
	}	
	
	public static void main(String[] args) throws Exception
	{
		if(args.length < 1)
			VeriFLA.fatalError("Too few arguments: "+args.length+
				"\nSintax is:\n\tjava VeriFLA <propertiesFileName> [<sendMonResetAndRun>=0/1 (default 0)] [sourceToRebuild_capture]\n"+
				"Examples:\n1. Wait for FPGA to send capture:\n\tjava VeriFLA verifla_properties_keyboard.txt\n"+
				"2. Send to the monitor reset and run and wait for FPGA to send capture:\n\tjava VeriFLA verifla_properties_keyboard.txt 1\n"
				);
		// 1st arg.
		System.out.println("propertiesFileName = " + args[0]);
		// 2nd arg.
		sendMonResetAndRun = 0;
		if(args.length >= 2) {
			System.out.println(" sendMonResetAndRun = " + args[1]);
			sendMonResetAndRun = Integer.parseInt(args[1]);
		}
		// 3rd arg.
		String sourceToRebuildCaptureFile=null;
		if(args.length >= 3) {
			System.out.println(" sourceToRebuild_capture = " + args[2]);
			sourceToRebuildCaptureFile = args[2];
		}
		VeriFLA verifla;
		verifla = new VeriFLA();
		verifla.job(args[0], sourceToRebuildCaptureFile);
	}
	
	// This java app. data members				
	boolean debugVeriFLA=true;

	String propertiesFileName;
	Properties properties;
	SerialPort serialPort;
	String strBaudRate;
	final static String NAME = "LA";
	final static String STR_ORIGINAL_CAPTURE_DUMP = "ORIGINAL CAPTURE DUMP";
	final static int USERCMD_RESET=0x00, USERCMD_RUN = 0x01;
	byte [][] memoryLineBytes;
	int octetsPerWord, totalmemoryDataBytes;
	int totalSignals;
	public static int sendMonResetAndRun=0;
	int clockPeriod;

	// Properties file members
	String portName;
	int memWords, memWordLenBits, dataWordLenBits, clonesWordLenBits,
		triggerMatchMemAddr, maxSamplesAfterTrigger;
	//int [] triggerLastValue;
	String strTimescaleUnit, strTimescalePrecision;
	int signalGroups;
	String [] groupName;
	int [] groupSize, groupEndian;
}
