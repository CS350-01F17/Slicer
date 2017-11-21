/*
   Device Controller for a generic 3D printer

   John Caley, Melissa Chillington, David Hanely, Steven Rollo

   Usage:
   DeviceController can be created any time prior to or when the printer connection is started
   A serial port name and baud rate must be supplied in either the constructor, or the
   connectSerial() method in order to connect to a printer
   Printing jobs can be started with startPrintJob() - see the method for more info
   pause/resume/stopJob() control the state of the current print job
   Only one job can be run at once, isJobRunning() check if one is running
   Call disconnectSerial() prior to ending the program or dispoising of a DeviceController instance

   processing.serial.* must also be imported in the main Processing applet to use this class

   Some notes and thoughts:
   Having multiple instances of DeviceController is untested, and we are unsure
   how the Processing classes (Serial, PApplet) would react to such a situation
*/

/*
   We need access to PApplet in the external class to use processing's serial
    lib. We also need Thread so the serial communications can be run in parallel
    with the rest of the program
*/

import processing.core.*;
import processing.serial.*;
import java.lang.Thread;
import java.util.ArrayList;


public class DeviceController extends Thread {

   /*
      Public interface
   */

   /*
      First constructor for DeviceController. Used when the printer serial import
       is known and available. Serial port params are passed to the constructor,
       and a connection is attempted.
       Throws a RuntimeException if the serial port provided cannot be opened
   */
   DeviceController(PApplet thisApplet, String port, int baudRate) throws RuntimeException {
     this.thisApplet = thisApplet;
     this.port = port;
     this.baudRate = baudRate;
      //Create a serial connection to the printer on the specified port / baud rate
      // Serial needs access to the PApplet object of the main program
      /*
      if(!connectSerial(thisApplet, port, baudRate)) {
         //This version of the consturctor will fail if the supplied serial port is unavailable
         throw new RuntimeException("Failed to create DeviceController with serial" +
         " port: failed to open port " + port);
      }
      */
      //delay for printer
      //long t = System.currentTimeMillis();
      //while (System.currentTimeMillis() - t != 2000){}
   }
   /*
      Second constructor. Allows testMode to be set. Does not attempt to
       start a serial connection
   */
   DeviceController(boolean testMode) {
      //Set test mode
      this.testMode = testMode;
      if(testMode) {
         System.out.println("Proceeding in test mode");
      }
   }
   /*
      Third constructor. Takes no params, testMode is false and no serial connection
       is attempted.
   */
   DeviceController() {
   }
   /*
      Starts a new print job in its own thread using the provided GCode "file".
       Expects an arraylist with one GCode command per entry. Commands should ideally
       not contain newlines. All interaction with the printer should go through this method.

       Returns true if a job started sucessfuly, returns false if a job is already running,
        or the serial port is not connected
   */
   public boolean startPrintJob(ArrayList<String> GCodeFile) {
      //Reset stop/pause requests
      synchronized(this) {
         stopRequest = false;
         pauseRequest = false;
      }

      //Currently, only one job can be running at a time
      // Also, the serial port must be connected, or test mode must be active
      //if(!isJobRunning() && (sdaConnected || testMode)) {
         //Store the GCode file internally, then start the printing thread
         this.GCode = GCodeFile;
         //run();
         start();
         return true;
      //}
      //return false;
   }
   /*
      Stops any currently running job
   */
   public boolean stopJob() {
      synchronized(this) {
         pauseRequest = false;
         stopRequest = true;
         return true;
      }
   }
   /*
      Pauses a currently running job
   */
   public boolean pauseJob() {
      synchronized(this) {
         pauseRequest = true;
         return true;
      }
   }
   /*
      Resumes a paused job
   */
   public boolean resumeJob() {
      synchronized(this) {
         pauseRequest = false;
         return true;
      }
   }
   /*
      Returns true if a job is running, otherwise false
   */
   public boolean isJobRunning() {
      synchronized(this) {
         return jobRunning;
      }
   }
   /*
      Set custom start GCode for the printing process
      TODO: Is passing a reference to ArrayList thread-safe?
   */
   public boolean setStartCode(ArrayList<String> startCode) {
      synchronized(this) {
         this.startCode = startCode;
         return true;
      }
   }
   /*
      Set custom end GCode for the printing process
      TODO: Is passing a reference to ArrayList thread-safe?
   */
   public boolean setEndCode(ArrayList<String> endCode) {
      synchronized(this) {
         this.endCode = endCode;
         return true;
      }
   }
   /*
      Preheats the bed and extruder to the specified temperatures
   */
   public boolean setPreheat(int bedTemp, int extruderTemp) {
      return true;
   }
   /*
      Runs the homing procedure
   */
   public boolean runHoming() {
      return true;
   }
   /*
      Connects to a printer on the specified serial port
      Returns true if the connection was successful, or false if the connection failed
   */
   public boolean connectSerial(PApplet thisApplet, String port, int baudRate) {
      if(!sdaConnected) {
         try {
            System.out.println("Connecting to printer on port " + port);

            serialCom = new Serial(thisApplet, port, baudRate);
            sdaConnected = true;

            System.out.println("Connected to port " + port);

            return true;
         }
         catch(RuntimeException e) {
           System.out.println("Failed to open serial port, aborting");
           return false;
         }
      }
      System.out.println("Serial port is already connected...");
      return false;
   }
   /*
      Disconnects the computer from the printer serial port. This should be called
      at program close, or if a disconnect button is implemented
      Returns true if disconnect was sucessful, or false if there was no connection to disconnect
   */
   public boolean disconnectSerial() {
      if(serialCom != null && sdaConnected) {
         serialCom.stop();
         sdaConnected = false;
         return true;
      }
      System.out.println("Serial port is already disconnected...");
      return false;
   }
   /*
      Checks if the serial port is connected
   */
   public boolean isSerialConnected() {
      return sdaConnected;
   }
   /*
      Enables test mode, for testing UI interaction and threading
      Print jobs will run without sending any commands to the serial port, and
      will not wait for responses
   */
   public boolean setTestMode(boolean testMode) {
      synchronized(this) {
         this.testMode = testMode;
         return true;
      }
   }
   /*
      The run() method is only implemented to fit the interface of java.Thread,
       this shouldn't be called directly by anyone
   */
   public void run() {
     if(!connectSerial(thisApplet, port, baudRate)) {
         //This version of the consturctor will fail if the supplied serial port is unavailable
         throw new RuntimeException("Failed to create DeviceController with serial" +
         " port: failed to open port " + port);
      }
      /*
      serialCom.write("");
      String response = "";
      do{
        response = serialCom.readString();
        if(response != null) {
           while(!response.contains("\r")) {
              String temp = serialCom.readString();
              response += ((temp == null) ? "" : temp);
           }
        } 
      }while (response != null && response != "start");
      */
      runPrintJob();
   }

   /*
      Private methods
   */

   /*
      Checks if a pauseRequest has been issued. For use by runPrintJob only.
   */
   private boolean pauseRequested() {
      synchronized(this) {
         return pauseRequest;
      }
   }
   /*
      Checks if a pauseRequest has been issued. For use by runPrintJob only.
   */
   private boolean stopRequested() {
      synchronized(this) {
         return stopRequest;
      }
   }
   /*
      Runs any custom start code code via using the printJob procedure
   */
   private boolean runStartCode() {
      if(startCode != null) {
         startPrintJob(startCode);
      }
      return true;
   }
   /*
      Runs any custom end code via using the printJob procedure
   */
   private boolean runStopCode() {
      if(endCode != null) {
         startPrintJob(endCode);
      }
      return true;
   }
   /*
      Main method for running print jobs (1+ line(s) of gcode)
       This method should always be invoked via startPrintJob() so it will run
       in its own thread
   */
   private boolean runPrintJob() {
      synchronized(this) {
         jobRunning = true;
      }

      runStartCode();

      for(int i = 0; i < GCode.size(); i++) {
         if(pauseRequested()) {
           System.out.println("Printing paused...");
         }
         while(pauseRequested()) {
            //This try-catch block is just to keep java happy when using sleep
            try {
               sleep(10);
            }
            catch(InterruptedException e) {
               e.printStackTrace();
            }
         }
         if(stopRequest) {
            System.out.println("Printing stopped");
            stopRequest = false;
            return false;
         }

         if(!GCode.get(i).startsWith(";")) {
            boolean status = sendGCodeLine(GCode.get(i).split(" ;")[0]);
            while(!status) {
               System.out.println("Line " + i + " failed, retrying");
               status = sendGCodeLine(GCode.get(i));
            }
            System.out.println("Line " + i + " sent successfuly");
         }
      }

      runStopCode();

      return true;
   }
   /*
      Sends a single gcode line to the printer and waits for a response,
       returns true if a success code was returned, otherwise returns false.
       Waiting times out after the # of ms in timeout.
       This method should only be invoked by runPrintJob, which will cause dropped
       commands and errors to be handled more gracefuly
   */
   private boolean sendGCodeLine(String line) {
      //Test mode codepath, skips sending commands to the printer
      synchronized(this) {
         //This try-catch block is just to keep java happy when using sleep
         if(testMode) {
            try {
               sleep(50);
            }
            catch(InterruptedException e) {
               e.printStackTrace();
            }
            return true;
         }
      }

      String response = "";
      long startTime = System.currentTimeMillis();
      serialCom.write(line + "\n");

      while(true) {
         response = serialCom.readString();
         if(response != null) {
            while(!response.contains("\r")) {
               String temp = serialCom.readString();
               response += ((temp == null) ? "" : temp);
            }
            System.out.println(response);
            if(response.contains("ok")) {
               return true;
            }
            else if(response.contains("wait")) {
               return true;
            }
            else if(response.startsWith("T")) {
               startTime = System.currentTimeMillis();
            }
         }
         if(System.currentTimeMillis() - startTime >= timeout) {
            System.out.println("Timed out...");
            return false;
         }
      }
   }

   /*
      Private instance variables
   */

   private Serial             serialCom;
   private ArrayList<String>  GCode;
   private ArrayList<String>  startCode;
   private ArrayList<String>  endCode;
   private PApplet            thisApplet;
   private String             port;
   private int                baudRate;
   private boolean            testMode      = false;
   private boolean            sdaConnected  = false;
   private boolean            pauseRequest  = false;
   private boolean            stopRequest   = false;
   private boolean            jobRunning    = false;
   private final int          timeout       = 10000;
};
