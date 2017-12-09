/*
 Device Controller for a generic 3D printer

 John Caley, Melissa Chillington, David Hanely, Steven Rollo

 Usage:
 DeviceController can be created any time prior to or when the printer connection is started
 A serial port name and baud rate must be supplied to the connectSerial() method in order to connect to a printer
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
import java.util.Arrays;

/**
 * Device Controller for a generic 3D printer
 * <p>
 * DeviceController can be created any time prior to or when the printer connection is started
 * A serial port name and baud rate must be supplied to the connectSerial() method in order to connect to a printer
 * Printing jobs can be started with startPrintJob() - see the method for more info
 * pause/resume/stopJob() control the state of the current print job
 * Only one job can be run at once, isJobRunning() check if one is running
 * Call disconnectSerial() prior to ending the program or dispoising of a DeviceController instance
 * processing.serial.* must also be imported in the main Processing applet to use this class
 *
 * @version 0.1
 *
 */
public class DeviceController extends Thread {
  /**
   * Main constructor
   * @param thisApplet The parent processing applet for the program. The Serial classes
   *                   used internally will be scoped to this PApplet
  */

  DeviceController(PApplet thisApplet) {
    this.thisApplet = thisApplet;
    sdaConnected = false;
  }

  /**
   * Test mode constructor
   * @param testMode When set to true, the device controller will be launched in test testMode.
   *                 While in test mode, print jobs can be stopped and started, but no commands
   *                 will be sent to a printer.
  */
  DeviceController(boolean testMode) {
    //Set test mode
    this.testMode = testMode;
    if (testMode) {
      System.out.println("Proceeding in test mode");
    }
  }

  /**
   * Starts a thread for serial communication
   * @param port A string containing the name of the serial port to connect to
   * @param baudRate The baud rate of the serial port to connect to
  */
  public void connectSerial(String port, int baudRate) {
    this.port = port;
    this.baudRate = baudRate;
    Thread t = new Thread(this);
    t.start();
  }

  /**
   * Closes serial port connection
   * @return Returns true if the serial port was disconnected successfuly
  */
  public boolean disconnectSerial() {
    if (serialCom != null && serialConnected()) {
      synchronized(serialCom) {
        serialCom.stop();
      }
      sdaConnected = false;
      return true;
    }
    System.out.println("Serial port is already disconnected...");
    return false;
  }

  /**
   * Main method used by the DeviceController thread. Please do not call this,
   * it is only public because of the structure of the Thread class
  */
  public void run() {
    if (testMode || _connectSerial()) {
      while (testMode || serialConnected()) {
        if (jobRequest) {
          synchronized(this) {
            jobRequest = false;
          }
          runPrintJob();
        } else {
          try {
            sleep(10);
          }
          catch(InterruptedException e) {
            e.printStackTrace();
          }
        }
      }
    }
  }

  /**
   * Requestes that the DeviceController stop a currently running print job
  */
  public void stopJob() {
    synchronized(this) {
      pauseRequest = false;
      stopRequest = true;
    }
  }

  /**
   * Requestes that the DeviceController pause a currently running print job
  */
  public void pauseJob() {
    synchronized(this) {
      pauseRequest = true;
    }
  }

  /**
   * Requestes that the DeviceController resume a currently paused print job
  */
  public void resumeJob() {
    synchronized(this) {
      pauseRequest = false;
    }
  }

  /**
   * Checks if DeviceController is connected to a serial import
   * @return Returns true if a serial port is connected
  */
  public boolean serialConnected() {
    synchronized(this) {
      return sdaConnected;
    }
  }

  /**
   * Checks if a print job is running
   * @return Returns true if a print job is running
  */
  public boolean isJobRunning() {
    synchronized(this) {
      return jobRunning;
    }
  }

  /**
   * Checks if a pause request has been issued, or the print job is paused
   * @return Returns true if a print job is paused
  */
  public boolean pauseRequested() {
    synchronized(this) {
      return pauseRequest;
    }
  }

  /**
   * Checks if a stop request has been issued
   * @return Returns true if a stop request has been issued
  */
  public boolean stopRequested() {
    synchronized(this) {
      return stopRequest;
    }
  }

  /**
   * Starts a new print job using the supplied GCode. A new print job will not startTime
   * if a current job is in progress, or a serial port is not connected
   * @param GCodeFile An array list containing GCode to be sent to the printer
   * @return Returns true if a new job was started successfuly
  */
  public boolean startPrintJob(ArrayList<String> GCodeFile) {
    //Reset stop/pause requests
    synchronized(this) {
      stopRequest = false;
      pauseRequest = false;
    }

    if (!isJobRunning() && (testMode || serialConnected())) {
      synchronized(this) {
        this.GCode = GCodeFile;
        jobRequest = true;
      }
      return true;
    }
    return false;
  }

  /*
    Private interface
  */

  /**
   * Executed by the DeviceController thread. Sends each GCode line to the printer,
   * and handles failed lines or resends
  */
  private void runPrintJob() {
    synchronized(this) {
      if (GCode == null) {
        //Don't start the job if no GCode has been provided
        return;
      }
      jobRunning = true;
    }

    //Wait for the printer to send a wait response. This shows the printer is booted
    // up and ready to accept commands
    String response = "";
    while (!testMode) {
      //The prusa i3 delimits lines with a carriage return
      response = serialCom.readStringUntil('\r');
      if (response != null) {
        //Check if the response is whay we want
        if (response.contains("wait")) {
          System.out.println("Starting print job...");
          break;
        }
      }
    }

    //Reset the printer's expected next line to line 1
    if(!testMode) {
      synchronized(serialCom) {
        serialCom.write("M110 N0\n");
      }
    }

    //Wait for a response from the M110 command
    while (!testMode) {
      response = serialCom.readStringUntil('\r');
      if (response != null) {
        if (response.contains("ok")) {
          break;
        }
      }
    }

    int lineNumber = 1;

    //Strip any BOMs from unicode GCode files
    GCode.set(0, GCode.get(0).replace("\ufeff", ""));
    GCode.set(0, GCode.get(0).replace("\ufffe", ""));

    //For each line of GCode
    for (int i = 0; i < GCode.size(); i++) {
      //If a pause request has been sent, sleep until a resume is sent
      if (pauseRequested()) {
        System.out.println("Printing paused...");
      }
      while (!stopRequested() && pauseRequested()) {
        //Thread.sleep requires the try...catch block because it throws an exception
        try {
          sleep(10);
        }
        catch(InterruptedException e) {
          e.printStackTrace();
        }
      }

      //If a stopRequest has been sent, stop sending gcode
      if (stopRequested()) {
        System.out.println("Printing stopped");
        stopRequest = false;
        synchronized(this) {
          jobRunning = false;
        }
        return;
      }

      //Skip comment lines
      if (!GCode.get(i).startsWith(";")) {
        //Only get code prior to any comments
        String line = GCode.get(i).split(";")[0];
        line = line.trim();
        //If line numbers have not been provided, add them
        if (!line.startsWith("N")) {
          line = "N" + lineNumber + " " + line;
        }
        //Print the line to the console
        System.out.println(line);
        //Send the line to the printer, resending until it has been executed successfuly
        if(!testMode) {
          while (!sendGCodeLine(line, lineNumber));
        }
        //Wait a little in between lines in test mode
        else {
          try {
            sleep(15);
          }
          catch(InterruptedException e) {
            e.printStackTrace();
          }
        }
        //Increment the line number. This is different from the loop counter, since
        // comment lines are not counted
        lineNumber++;
      }
    }
    //Print job is done
    synchronized(this) {
      jobRunning = false;
    }
  }

  /**
   * Sends single GCode command to printer
   * @param line The GCode line to be sent
   * @param lineNumber The line number associated with the line. This is used to check
   *                   if it has been accepted
   * @return Returns true if the line was sent successfuly. If false, the line should be
   *         sent again
  */
  private boolean sendGCodeLine(String line, int lineNumber) {
    String response = "";
    long startTime = System.currentTimeMillis();

    //Add missing newlines if necessary
    if (!line.endsWith("\n")) {
      line += "\n";
    }

    //Write the line to the serial port
    try {
      synchronized(serialCom) {
        serialCom.write(line);
      }
    }
    catch (Exception e) {
      e.printStackTrace();
    }

    //Loop until we get a response, time out, or the job is stopped
    while (!stopRequested()) {
      try {
        synchronized(serialCom) {
          //Try to get a response
          response = serialCom.readStringUntil('\r');
        }
      }
      catch (Exception e) {
        e.printStackTrace();
      }

      if (response != null) {
        //Print the response
        System.out.println(response);
        //If the response indicates the line was sent OK (or should not be sent again)
        // return true
        //If the response conatins temperature data, continue to wait until heating is finished
        //Otherwise, the line needs to be resent
        if (response.contains("ok " + lineNumber) || response.contains("skip " + lineNumber)) {
          return true;
        } else if (response.contains("T:")) {
          startTime = System.currentTimeMillis();
        } else if (response.contains("Resend") || response.contains("ok")) {
          return false;
        }
      }
      //If waiting has timed out, resend the line
      if (System.currentTimeMillis() - startTime >= timeout) {
        System.out.println("Timed out...");
        return false;
      }
    }
    return true;
  }

  /**
   * Connects to a printer on the specified serial port
   * @return Returns true if the connection was successful, or false if the connection failed
  */
  private boolean _connectSerial() {
    if (!serialConnected() && !testMode) {
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
    else if(testMode) {
      sdaConnected = true;
      return true;
    }
    System.out.println("Serial port is already connected...");
    return false;
  }

  private Serial             serialCom;
  private ArrayList<String>  GCode;
  private PApplet            thisApplet;
  private String             port;
  private int                baudRate;
  private boolean            sdaConnected  = false;
  private boolean            pauseRequest  = false;
  private boolean            stopRequest   = false;
  private boolean            jobRequest    = false;
  private boolean            jobRunning    = false;
  private boolean            testMode      = false;
  private final int          timeout       = 60000;
};
