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
   //First, instantiate the class providing the PApplet (usually this),
   // a serial port name, and the baud rate.
   // The last parameter controls test mode (true = don't send commands to printer)
   //The constructor throws a RuntimeExcetpion if the serial port cannot be opened,
   // so use it in a try-catch block
   try {
     devControl = new DeviceController(this, "/dev/ttyUSB0", 115200, true);
   }
   catch(RuntimeException e) {
     e.printStackTrace();
     println("Failed to open serial port, aborting");
     return;
   }

   //Get GCode data from somewhere, this example loads it from a file
   //DeviceController expects an array list of seperate strings
   gcode = new ArrayList<String>(Arrays.asList(loadStrings("torus_flat.gcode")));

   //Call the startPrintJob method with the provided gcode to start printing
   devControl.startPrintJob(gcode);

   //Test pausing, resuming, and stopping the print job after various intervals
   delay(12000);
   println("Main thread requesting pause");
   devControl.pauseJob();

   delay(5000);
   println("Main thread requesting resume");
   devControl.resumeJob();

   delay(10000);
   println("Main thread requesting stop");
   devControl.stopJob();

   println("Main thread done");
}

void loop() {

}
