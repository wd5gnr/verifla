/*
UARTSendReceive.java
License: GNU GPL

Revision history:
revistion date: 2018/07/20; author: Laurentiu Duca
- port of SerialPort jssc instead of rxtx
revision date: 2007/Sep/03;  author: Laurentiu Duca
- captureOnly feature
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

public class UARTSendReceive extends Object {

	// Data members are declared at the end.

	/**
	 * Creates a new object.
	 *
	 */	
	public UARTSendReceive() {
		this.serialPort = null;
		//this.properties = new Properties();
	}

	/**
	 * Attaches the given serial serialPort to the device object.
	 * The method will try to open the serialPort.
	 */
	public boolean attach(String portName, String strBaudRate, String parity) {
		serialPort = new SerialPort(portName);

		byte pb[]=parity.getBytes();
		int b=pb[0]=='1'?SerialPort.PARITY_ODD:SerialPort.PARITY_NONE;
		System.out.println("parity="+b);
		try {
			serialPort.openPort();//Open serial port
			int baudrate=Integer.parseInt(strBaudRate);
				//strBaudRate.equals("115200")?SerialPort.BAUDRATE_115200:
				//strBaudRate.equals("38400")?SerialPort.BAUDRATE_38400:SerialPort.BAUDRATE_9600;
			serialPort.setParams(baudrate, 
                             SerialPort.DATABITS_8,
                             SerialPort.STOPBITS_1, 
                             b); //SerialPort.PARITY_NONE);
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
	
	public void sendReceive(String msg) throws IOException, SerialPortException {
		byte rawByte[]=new byte[1];
		rawByte = msg.getBytes();
		
		System.out.println("Sending...");
		serialPort.writeBytes(rawByte);
		System.out.println("Done sending.");
		
		// Read Captured data
		System.out.println("Reading");
		byte readByte[] = serialPort.readBytes(1);
		System.out.printf("Read: '%c'=0x%x\n", (char) readByte[0], (int) readByte[0]);
	}

	public void getCapturedData(String portName, String strBaudRate, String parity, String msg)
	{
		boolean found;
		found = attach(portName, strBaudRate, parity);
		if(!found) {
			System.out.println("Port " + portName + " not found.\n");
			System.exit(0);
		}		
		try {
			sendReceive(msg);
		} catch (Exception ex) {
			ex.printStackTrace(System.out);
		}
		detach();				
	}
	

	public static void fatalError(String errorName)
	{
		System.out.println("Fatal error: " + errorName);
		System.exit(-1);
	}
	

	public static void main(String[] args) throws Exception
	{
		if(args.length != 4)
			UARTSendReceive.fatalError("Number of arguments is not 4; is "+args.length+"\n"+
				"Sintax is:\njava UARTSendReceive <port> <baudrate> <parity (0|1)> <char>\n"+
				"Examples:\n"+
				"java UARTSendReceive COM5 9600 0 a\n"+
				"java UARTSendReceive /dev/ttyUSB0 115200 0 a\n");
		// 1st arg.
		System.out.println("port = " + args[0]);
		System.out.println("baudrate = " + args[1]);
		//if(!args[1].equals("115200") && !args[1].equals("38400") && !args[1].equals("9600"))
		//	fatalError("Invalid baudrate");
		System.out.println("parity = " + args[2]);
		System.out.println("char = " + args[3]);
		UARTSendReceive usr;
		usr = new UARTSendReceive();
		usr.getCapturedData(args[0], args[1], args[2], args[3]);
	}
	
	SerialPort serialPort;
	byte [][] memoryDataWords;
	int octetsPerWord, idOfTypeBitInLastOctet, totalmemoryDataBytes;
	// Properties file members
	String portName;
}
