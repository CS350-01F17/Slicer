/*
  This sketch provides an example of using the DeviceController class with a processing sketch
 */

//processing.serial.* must be included in the main sketch as well as the DeviceController.java class
import processing.serial.*;
import java.util.Arrays;

DeviceController devControl;
ArrayList<String> gcode;

/*
   The setop and loop methods provide example usage for the DeviceController class
 */
void setup() {
  print(Serial.list());
  /*
      First, instantiate DeviceController. Three constructors are provided
   1) For immidiate connection to a serial port:
   provide the PApplet (usually this), a serial port name, and the baud rate.
   The constructor throws a RuntimeExcetpion if the serial port cannot be opened,
   so use it in a try-catch block
   */

  try {
    devControl = new DeviceController(true);
  }
  catch(RuntimeException e) {
    e.printStackTrace();
    println("Failed to open serial port, aborting");
    return;
  }

  devControl.connectSerial("/dev/pts/3", 38400);

  /*
      2) For using test mode. A single boolean is provided.
   true == testMode enabled. No serial connection is made
   */
  //devControl = new DeviceController(true);

  /*
      3) For creating a DeviceController when the serial port is unavailable
   Takes no parameters, a connection can be made later using the
   connectSerial() method
   */

  //devControl = new DeviceController();

  //Get GCode data from somewhere, this example loads it from a file
  //DeviceController expects an array list of seperate strings
  gcode = new ArrayList<String>(Arrays.asList(loadStrings("torus_flat.gcode")));

  //Call the startPrintJob method with the provided gcode to start printing
  devControl.startPrintJob(gcode);
  delay(10000);
  devControl.pauseJob();
  delay(1000);
  devControl.stopJob();
  devControl.startPrintJob(gcode);
  //Test pausing, resuming, and stopping the print job after various intervals
  /*delay(4000);
  println("Main thread requesting pause");
  devControl.pauseJob();

  delay(4000);
  println("Main thread requesting resume");
  devControl.resumeJob();

  delay(1000);
  println("Main thread requesting stop");
  devControl.stopJob();

  delay(1000);
  println("Main thread requesting start new");
  devControl.startPrintJob(gcode);

  delay(1000);
  println("Main thread requesting stop");
  devControl.stopJob();
  println("Main thread done");*/
}

void draw() {
}