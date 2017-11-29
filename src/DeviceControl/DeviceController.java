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
    Main constructor
  */
  DeviceController(PApplet thisApplet) {
    this.thisApplet = thisApplet;
    sdaConnected = false;
  }
  /*
    Test mode constructor
  */
  DeviceController(boolean testMode) {
    //Set test mode
    this.testMode = testMode;
    if (testMode) {
      System.out.println("Proceeding in test mode");
    }
  }

  //default constructor
  DeviceController() {
  }

  //Starts a thread for serial communication
  //Returns false if the serial port is already connected
  public void connectSerial(String port, int baudRate) {
    this.port = port;
    this.baudRate = baudRate;
    Thread t = new Thread(this);
    t.start();
  }

  //method used by thread
  public void run() {
    if (_connectSerial()) {
      while (sdaConnected) {
        if (jobRequest) {
          runPrintJob();
          jobRequest = false;
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

  public boolean stopJob() {
    synchronized(this) {
      pauseRequest = false;
      stopRequest = true;
      return true;
    }
  }

  public boolean pauseJob() {
    synchronized(this) {
      pauseRequest = true;
      return true;
    }
  }

  public boolean resumeJob() {
    synchronized(this) {
      pauseRequest = false;
      return true;
    }
  }

  public boolean isJobRunning() {
    synchronized(this) {
      return jobRunning;
    }
  }

  //Connects to a printer on the specified serial port Returns true if the connection was successful, or false if the connection failed
  private boolean _connectSerial() {
    if (!sdaConnected) {
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

  //called to start a print job
  public boolean startPrintJob(ArrayList<String> GCodeFile) {
    //Reset stop/pause requests
    synchronized(this) {
      stopRequest = false;
      pauseRequest = false;
    }

    if (!isJobRunning() && (sdaConnected || testMode)) {
      //Store the GCode file internally, then start the printing thread
      this.GCode = GCodeFile;
      jobRequest = true;
      return true;
    }
    return false;
  }

  //executed by thread when print job request made
  private boolean runPrintJob() {
    synchronized(this) {
      if (GCode == null) {
        return false;
      }
      jobRunning = true;
    }

    String response = "";
    while (!testMode) {
      response = serialCom.readStringUntil('\r');
      if (response != null) {
        if (response.contains("wait")) {
          System.out.println("Starting...");
          break;
        }
      }
    }

    for (int i = 0; i < GCode.size(); i++) {

      if (pauseRequested()) {
        System.out.println("Printing paused...");
      }
      while (!stopRequest && pauseRequested()) {
        try {
          sleep(10);
        }
        catch(InterruptedException e) {
          e.printStackTrace();
        }
      }

      if (stopRequest) {
        System.out.println("Printing stopped");
        stopRequest = false;
        synchronized(this) {
          jobRunning = false;
        }
        return true;
      }

      int lineNumber = 1;
      GCode.set(0, GCode.get(0).replace("\ufeff", ""));
      GCode.set(0, GCode.get(0).replace("\ufffe", ""));

      if (!GCode.get(i).startsWith(";")) {
        String line = GCode.get(i).split(";")[0];
        line = line.trim();
        if (!line.startsWith("N")) {
          line = "N" + lineNumber + " " + line;
        }
        //System.out.println(line);
        while (!sendGCodeLine(line, lineNumber));
        lineNumber++;
      }
    }

    synchronized(this) {
      jobRunning = false;
    }
    return true;
  }

  //send single g code command to printer
  private boolean sendGCodeLine(String line, int lineNumber) {

    String response = "";
    long startTime = System.currentTimeMillis();
    if (!line.endsWith("\n")) {
      line += "\n";
    }
    try {
      synchronized(serialCom) {
        serialCom.write(line);
      }
    }
    catch (Exception e) {
      e.printStackTrace();
    }

    while (true) {
      try {
        synchronized(serialCom) {
          response = serialCom.readStringUntil('\r');
        }
      }
      catch (Exception e) {
        e.printStackTrace();
      }

      if (response != null) {
        System.out.println(response);
        if (response.contains("ok " + lineNumber)) {
          return true;
        } else if (response.contains("T:")) {
          startTime = System.currentTimeMillis();
        } else if(response.contains("Resend") || response.contains("ok")) {
          return false;
        }
      }
      if (System.currentTimeMillis() - startTime >= timeout) {
        System.out.println("Timed out...");
        return false;
      }
    }
  }

  //closes serial port connection
  public boolean disconnectSerial() {
    if (serialCom != null && sdaConnected) {
      synchronized(serialCom) {
        serialCom.stop();
      }
      sdaConnected = false;
      return true;
    }
    System.out.println("Serial port is already disconnected...");
    return false;
  }

  private boolean pauseRequested() {
    synchronized(this) {
      return pauseRequest;
    }
  }

  private boolean stopRequested() {
    synchronized(this) {
      return stopRequest;
    }
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
