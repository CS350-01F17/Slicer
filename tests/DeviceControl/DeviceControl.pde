/*
  This sketch provides an example of using the DeviceController class with a processing sketch
  John Caley, Melissa Chillington, David Hanely, Steven Rollo
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
    First, instantiate DeviceController. Two constructors are provided
    1) For use with a device connected to a serial port. The constructor must be
    provided the PApplet (usually this)
  */

  devControl = new DeviceController(this);

  //Then, use connectSerial to connect to the desired serial port
  devControl.connectSerial("/dev/ttyUSB0", 115200);

  /*
    2) For using test mode. A single boolean is provided.
    true == testMode enabled. No serial connection is made
  */

  //devControl = new DeviceController(true);

  //Get GCode data from somewhere, this example loads it from a file
  //DeviceController expects an array list of seperate strings
  gcode = new ArrayList<String>(Arrays.asList(loadStrings("torus_flat.gcode")));

  //Call the startPrintJob method with the provided gcode to start printing
  devControl.startPrintJob(gcode);

  //Test pausing, resuming, and stopping the print job after various intervals
  //delay(4000);
  //println("Main thread requesting pause");
  //devControl.pauseJob();

  //delay(4000);
  //println("Main thread requesting resume");
  //devControl.resumeJob();

  //delay(1000);
  //println("Main thread requesting stop");
  //devControl.stopJob();

  //delay(1000);
  //println("Main thread requesting start new");
  //devControl.startPrintJob(gcode);

  //delay(1000);
  //println("Main thread requesting stop");
  //devControl.stopJob();
  println("Main thread done");
}

void draw() {
}
