/*
GUI for 3D printer

Authors:
Zachary Boylan, Zaid Bhujwala, Rebecca Peralta, George Ventura

Required Processing Libraries needed before running gui.pde:
  - G4P
  - ToxicLibs

To start GUI, simply press the "Play" button on Processing 3.3.6 or run gui.pde by double clicking
it.
This version is a first prototype so not all features are present/functional but are accurate.
All features are mattered to change in final implementation.
*/

import processing.core.PApplet;
import g4p_controls.*;
import java.awt.*;
import java.io.File;

import processing.serial.*;
import java.util.Arrays;

import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.processing.*;

TriangleMesh mesh;
ToxiclibsSupport gfx;

//default max & min temptures for printer head and bed
int TEMP_MAX = 400;
int TEMP_MIN = 0;

//Create Device Controller object
DeviceController devControl = new DeviceController(this);
//  ***   To use Device Controller in test mode   ***
//DeviceController devControl = new DeviceController(true);
ArrayList<String> gcode;

//For render & slicing
PGraphics rendering;
//RenderControler vis;
boolean realsed = true;
boolean confirmedClicked = false;

int i=0;
int j=0;

Model test;

int last;

public void setup(){
  size(1570, 950, P3D);    //  , P3D needed for showing render
  //surface.setResizable(true);
  createGUI();
  frameRate(10);
  println("OS being used by user = " + System.getProperty("os.name"));
  layerScale = round2(layerScaleSlider.getValueF(), 2);
  port = serialDevices.getSelectedText();
  //logTextBox.setTextEditEnabled(false);
  inputWindow.setVisible(false);
  warmupWindow.setVisible(false);
  //logWindow.setVisible(false);
  errorWindow.setVisible(false);
  startPrintBtn.setVisible(false);
  pausePrintBtn.setVisible(false);
  cancelPrintBtn.setVisible(false);
  homingBtn.setVisible(false);
  bedTempTextBox.setText("50");
  headTempTextBox.setText("208");
  baudRateTextBox.setText("115200");
  xTextBox.setText("200");
  yTextBox.setText("200");
  zTextBox.setText("150");
  infill = round2(infillSlider.getValueF(), 2);
  filamentDiameter = round2(filamentSlider.getValueF(), 2);
  nozzleDiameter = round2(nozzleSlider.getValueF(), 2);
  bedTemp = Integer.parseInt(bedTempTextBox.getText());
  headTemp = Integer.parseInt(headTempTextBox.getText());
  baudRate = Integer.parseInt(baudRateTextBox.getText());
  xArea = Integer.parseInt(xTextBox.getText());
  yArea = Integer.parseInt(yTextBox.getText());
  zArea = Integer.parseInt(zTextBox.getText());
  
}

public void draw(){
  background(230);
  line(1130, 0, 1130, 950);
  line(1130, 650, 1570, 650);
  stroke(126);
  updateStatusLabel();



  //}

  if (confirmedClicked){
    lights();
    translate(550, 450, 0);
    rotateX(mouseY*0.01);
    rotateY(mouseX*0.01);
    gfx.origin(new Vec3D(),200);
    noStroke();
    gfx.mesh(mesh,false,10);
  }


}

 public static float round2(float number, int scale) {
    int pow = 10;
    for (int i = 1; i < scale; i++)
        pow *= 10;
    float tmp = number * pow;
    return ( (float) ( (int) ((tmp - (int) tmp) >= 0.5f ? tmp + 1 : tmp) ) ) / pow;
}
                         //Event Handlers

//Choose File Button Click
public void chooseFileBtn_click(GButton source, GEvent event) { //_CODE_:chooseFileBtn:320943:
  println("button1 - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Choose file button clicked");
  //Select New File
  STLFile = null;
  confirmedClicked = false;
  fileTextBox.setText("Choose file with browse ->");
  //Show the input Window
  inputWindow.setVisible(true);
} //_CODE_:chooseFileBtn:320943:



//Serial Devices DropList Click
public void serialDevices_click1(GDropList source, GEvent event) { //_CODE_:serialDevices:306859:
  println("serialDevices - GDropList >> GEvent." + event + " @ " + millis());
  printArray(Serial.list());
  if (Serial.list().length != 0){
    port = source.getSelectedText();}

  if((headTemp != null && bedTemp != null) && baudRate != null && port != null && !gcode.isEmpty()){

      startPrintBtn.setVisible(true);
      pausePrintBtn.setVisible(true);
      cancelPrintBtn.setVisible(true);
      homingBtn.setVisible(true);
  }

  println("Port = " + port);
  //logTextBox.appendText("Port = " + port);
} //_CODE_:serialDevices:306859:



//Baud Rate TextBox Change
public void baudRateTextBox_change(GTextField source, GEvent event) {
  baudRate = Integer.parseInt(baudRateTextBox.getText());
  
  if((headTemp != null && bedTemp != null) && baudRate != null && port != null && !gcode.isEmpty()){
  
      startPrintBtn.setVisible(true);
      pausePrintBtn.setVisible(true);
      cancelPrintBtn.setVisible(true);
      homingBtn.setVisible(true);
  }

  println("baudRate = " + baudRate);
}



//Print When Ready Box Clicked
public void printWhenReadyBox_clicked(GCheckbox source, GEvent event) { //_CODE_:printWhenReadyBox:392431:
  if (printWhenReadyBox.isSelected() == false)
      printWhenReady = false;
  else
      printWhenReady = true;

  println("printWhenReady is " + printWhenReady);
  //logTextBox.appendText("printWhenReady is " + printWhenReady);
} //_CODE_:printWhenReadyBox:392431:



//Infill Slider Change
public void qualitySlider_change(GSlider source, GEvent event) { //_CODE_:infillSlider:696453:
  // var name = infillSlider
  // Team wants value form 0.0 - 1.0 = divide by 100 if slider range is 0.0 - 100.0
  //infill = infillSlider.getValueF();   // round2 function will set number of decimals you want for infill
  infill = round2(infillSlider.getValueF(), 2);

  println("infill = " + infill);

} //_CODE_:infillSlider:696453:

// checks for constraints to values stored in xTextBox, yTextBox, zTextBox
// if out of range, uses a default min/max value
public void areaTextfield_change(GTextField source, GEvent event) {
    if (event == GEvent.LOST_FOCUS) {
        int area = Integer.parseInt(source.getText());  // get string from txtbox convert to int
        if (area < 1)
            source.setText("1");
        if (area > 200)
            source.setText("200");
        area = Integer.parseInt(source.getText());   //get new value
        // find which control sent the event
        if (source == xTextBox)
            xArea = area;
        else if (source == yTextBox)
            yArea = area;
        else if (source == zTextBox)
            zArea = area;

        println("x: " + xArea + ", y: " + yArea + ", z: " + zArea);
        //logTextBox.appendText("x: " + xArea + ", y: " + yArea + ", z: " + zArea);
    }
}

//Filament Slider Change
public void filamentSlider_change(GSlider source, GEvent event) { 
  filamentDiameter = round2(filamentSlider.getValueF(), 2);
  println("Filament diameter = " + filamentDiameter);
} 

//Nozzle Slider Change
public void nozzleSlider_change(GSlider source, GEvent event) { //_CODE_:nozzleSlider:915112:
  nozzleDiameter = round2(nozzleSlider.getValueF(), 2);
  println("Nozzle diameter = " + nozzleDiameter);
} //_CODE_:nozzleSlider:915112:



//Layer Scale Slider Change
public void sliderLayerScale_change(GSlider source, GEvent event) { //_CODE_:layerScaleSlider:493757:
  layerScale = round2(layerScaleSlider.getValueF(), 2);
  println("Layer scale = " + layerScale);
  //logTextBox.appendText("Layer scale = " + layerScale);
} //_CODE_:layercaleSlider:493757:



//Warm Up Window
synchronized public void warmupWin_draw(PApplet appc, GWinData data) {
  appc.background(230);
}

//Warm Up Button Clicked
public void warmUpBtn_click(GButton source, GEvent event) { //_CODE_:warmUpBtn:690847:
  println("button1 - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Warm up button clicked");
  warmupWindow.setVisible(true);
} //_CODE_:warmUpBtn:690847:

//Warmup Confirm Button Click
public void warmupconfirmBtn_click(GButton source, GEvent event) {
  println("warmupconfirmBtn - GButton >> GEvent." + event + " @ " + millis());
  //Set Head Temp
  headTemp = Integer.parseInt(headTempTextBox.getText());
  println("Head Temperature = " + headTemp);

  //Set Bed Temp
  bedTemp = Integer.parseInt(bedTempTextBox.getText());
  println("Bed Temperature = " + bedTemp);
  
  if((headTemp != null && bedTemp != null) && baudRate != null && port != null && !gcode.isEmpty()){

      startPrintBtn.setVisible(true);
      pausePrintBtn.setVisible(true);
      cancelPrintBtn.setVisible(true);
      homingBtn.setVisible(true);
  }

  warmupWindow.setVisible(false);
}
//Warmup Cancel Button Click
public void warmupcancelBtn_click(GButton source, GEvent event) {
  println("warmupcancelBtn - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Warm up cancel button clicked");
  warmupWindow.setVisible(false);
}


//Homing Button Clicked
public void homingBtn_click(GButton source, GEvent event) { //_CODE_:recenterHeadBtn:245560:
  println("homingBtn - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Homing button clicked");

  ArrayList<String> homingCode = new ArrayList<String>();
  homingCode.add(homing[0]);   // Normal homing   G28: Move to Origin
  // Will likely crash if not already connected to printer or if not in test mode
  devControl.startPrintJob(homingCode);  //Need to pass ArrayList<String>
} //_CODE_:homingBtn:245560:


//Connect/disconnect to Printer Button Clicked
public void connectBtn_click(GButton source, GEvent event) { //_CODE_:connectBtn:421460:

  println("Connect/disconnect to printer button clicked");
  
  if (connectBtn.getText() == "Connect to Printer"){
    devControl.connectSerial(port, baudRate);
    if((headTemp != null && bedTemp != null) && baudRate != null && port != null && !gcode.isEmpty()){
      startPrintBtn.setVisible(true);
      pausePrintBtn.setVisible(true);
      cancelPrintBtn.setVisible(true);
      homingBtn.setVisible(true);
    }
    try {
      Thread.sleep(1000);                 //Need delay for next if stmt as connectSerial() is not instant
    } catch(InterruptedException ex) {
      Thread.currentThread().interrupt();
    }
    if (devControl.serialConnected())
    {
      connectBtn.setText("Disconnect");
    }
  }
  else {
    devControl.disconnectSerial();
    if (!devControl.serialConnected())
    {
      connectBtn.setText("Connect to Printer");  // allows you to pause more than once per print job
    }
  }
  //logTextBox.appendText("Connect to printer button clicked");
} //_CODE_:connectBtn:421460:

//Start Button Click
public void startPrintBtn_click(GButton source, GEvent event) { //_CODE_:startPrintBtn:735941:
  println("Start Print button pressed");
  devControl.startPrintJob(gcode);
}//_CODE_:startPrintBtn:735941:



//Pause Button Click
public void pausePrintBtn_click(GButton source, GEvent event) { //_CODE_:pausePrintBtn:624877:
  println("Pause / Resume button pressed");
  //logTextBox.appendText("Pause / Resume button pressed");

  if (pausePrintBtn.getText() == "Pause"){
    devControl.pauseJob();
    pausePrintBtn.setText("Resume");
  }
  else {
    devControl.resumeJob();
    pausePrintBtn.setText("Pause");    // allows you to pause more than once per print job
  }
} //_CODE_:pausePrintBtn:624877:


//Cancel Button Click
public void cancelPrintBtn_click(GButton source, GEvent event) { //_CODE_:cancelPrintBtn:781425:
  println("Cancel Print button pressed");
  //logTextBox.appendText("Cancel Print button pressed");
  devControl.stopJob();
  
  try {
      Thread.sleep(1000);                 //Need delay before sending cool down codes as stopJob() is not instant
    } catch(InterruptedException ex) {
      Thread.currentThread().interrupt();
    }

  ArrayList<String> cooldownHomingCode = new ArrayList<String>();
  cooldownHomingCode.add(cooldownHoming[0]);  // When print job is complete or aborted - "after printing, we should only move the x/y axis out of the way. Moving the head down could hit the printed object"
  cooldownHomingCode.add(cooldownHoming[1]);
  cooldownHomingCode.add(cooldownHoming[2]);
  cooldownHomingCode.add(cooldownHoming[3]);

  devControl.startPrintJob(cooldownHomingCode);
} //_CODE_:cancelPrintBtn:781425:


//Console Button Click
//public void consoleBtn_click(GButton source, GEvent event) { //_CODE_:cancelPrintBtn:781425:
//  println("Open Console window button pressed");
//  //logTextBox.appendText("Open Console window button pressed");
//  logWindow.setVisible(true);
//} //_CODE_:cancelPrintBtn:781425:


////Log Window
//synchronized public void logWin_draw1(PApplet appc, GWinData data) {
//  appc.background(230);
//}

//Log Cancel Button Click
//public void logCloseBtn_click(GButton source, GEvent event) {
//  println("logCloseBtn - GButton >> GEvent." + event + " @ " + millis());
//  //logTextBox.appendText("Close Console window button clicked");
//  logWindow.setVisible(false);
//}

//Arrow Button Clicked
public void rightArrowbtn_click1(GButton source, GEvent event) { //_CODE_:rightArrowbtn:338278:
  println("rightArrowbtn - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Right arrow button clicked");
} //_CODE_:rightArrowbtn:338278:

public void upArrowbtn_click1(GButton source, GEvent event) { //_CODE_:upArrowbtn:481853:
  println("upArrowbtn - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Up arrow button clicked");
} //_CODE_:upArrowbtn:481853:

public void leftArrowbtn_click1(GButton source, GEvent event) { //_CODE_:leftArrowbtn:840976:
  println("leftArrowbtn - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Left arrow button clicked");
} //_CODE_:leftArrowbtn:840976:

public void downArrowbtn_click1(GButton source, GEvent event) { //_CODE_:downArrowbtn:888588:
  println("downArrowbtn - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Down arrow button clicked");
} //_CODE_:downArrowbtn:888588:



//Choose File Window
synchronized public void win_draw1(PApplet appc, GWinData data) { //_CODE_:inputWindow:608766:
  appc.background(230);
} //_CODE_:inputWindow:608766:

//File TextBox Change
public void fileTextBox_change(GTextField source, GEvent event) { //_CODE_:fileTextBox:274303:
  println("fileTextBox - GTextField >> GEvent." + event + " @ " + millis());
} //_CODE_:fileTextBox:274303:

//Select File Button Click
public void searchFileBtn_click(GButton source, GEvent event) { //_CODE_:searchFileBtn:687641:
  println("searchFileBtn - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Select File Button Clicked");
  selectInput("Select a STL file:", "fileSelected");
} //_CODE_:searchFileBtn:687641:

public void fileSelected(File selection) {
  STLFile = selection.getAbsolutePath();
  String fileExtension = STLFile.substring(STLFile.length() - 3);
  if ( !(fileExtension.toLowerCase()).equals("stl") )
  {
    errorTextbox.setText("Incorrect file type chosen (non-STL file type)");
    //logTextBox.appendText("Incorrect file type chosen (non-STL file type)");
    errorWindow.setVisible(true);
    STLFile = "";
  }
  mesh=(TriangleMesh)new STLReader().loadBinary(sketchPath(STLFile),STLReader.TRIANGLEMESH);
  gfx=new ToxiclibsSupport(this);
  fileTextBox.setText(STLFile);
}

//GCode TextBox Change - will not allow user to enter GCode at the moment - must pick an STL file
//public void gcodeTextBox_change(GTextArea source, GEvent event) { //_CODE_:gcodeTextBox:726640:
//  println("textarea1 - GTextArea >> GEvent." + event + " @ " + millis());
//} //_CODE_:gcodeTextBox:726640:

//Cancel Input Button Click
public void cancelInputBtn_click(GButton source, GEvent event) { //_CODE_:cancelInputBtn:629030:
  println("button1 - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Cancel Input File Button Clicked");
  inputWindow.setVisible(false);
} //_CODE_:cancelInputBtn:629030:

//Confirm Button Click
public void confirmBtn_click(GButton source, GEvent event) { //_CODE_:confirmBtn:275116:
  println("Confirm File Selection Button Clicked");
  //logTextBox.appendText("Confirm Input File Button Clicked");
  //logTextBox.appendText("Layer scale = " + layerScale);
  
  // For new file chosen - isolate just the file name to display it on the UI
  //println(new File(STLFile).getName());
  fileName = new File(STLFile).getName();
  
    
  if (fileTextBox.getText() == STLFile) {
    currentFile.setText("File selected: " + fileName);
    inputWindow.setVisible(false);
    confirmedClicked = true;
  }

  
  //   Slicing functions - move to a separate "slice" button
  STLParser parser = new STLParser(STLFile); // Change %FILENAME% to the file name of the STL.
  ArrayList<Facet> facets = parser.parseSTL();
  // Slice object; includes output for timing the slicing procedure.
  Slicer slice = new Slicer(facets, layerScale, infill, filamentDiameter, nozzleDiameter); // Change %LAYERHEIGHT% to a value from 0.3 (low quality) to 0.1 (high quality).
        // ***new version - Slicer(ArrayList<Facet> facets, float layerHeight, float infill)
  ArrayList<Layer> layers = slice.sliceLayers();
  gcode = slice.createGCode(layers, headTemp, bedTemp, new PVector(xArea, yArea, zArea));   //creates GCode to send to printer
        // ***new version createGCode(ArrayList<Layer> layers, int extTemp, int bedTemp, PVector modelOffset)
  rendering = createGraphics(250, 250);  // Does this work?
  //println("Done slicing");
  
} //_CODE_:confirmBtn:275116:


//Error Window
synchronized public void errorWin_draw(PApplet appc, GWinData data) { //_CODE_:inputWindow:608766:
  appc.background(230);
} //_CODE_:inputWindow:608766:

//Error Close Button Click
public void errorCloseBtn_click(GButton source, GEvent event) {
  println("errorCloseBtn - GButton >> GEvent." + event + " @ " + millis());
  //logTextBox.appendText("Error Window Close Button Clicked");
  errorTextbox.setText(" ");
  errorWindow.setVisible(false);
}

// Checks if inputed temperature values are in range, if not uses default
public void tempTextBox_change(GTextField source, GEvent event) {
    println(event);
    if (event == GEvent.LOST_FOCUS) {               //cursor out event
        int tempValue = int(source.getText());      //convert string to int
        if (tempValue < 0)
            source.setText(str(TEMP_MIN));
        else if (tempValue > TEMP_MAX)
            source.setText(str(TEMP_MAX));
    }
}


                                      // Create all the GUI controls.
public void createGUI(){
  G4P.messagesEnabled(false);
  G4P.setGlobalColorScheme(GCScheme.BLUE_SCHEME);
  G4P.setCursor(ARROW);
  surface.setTitle("3D Printer");

  //Choose File Button
  chooseFileBtn = new GButton(this, 1160, 30, 100, 40);
  chooseFileBtn.setFont(new Font(Font_Type, Font.PLAIN, 16));
  chooseFileBtn.setText("Choose File");
  chooseFileBtn.addEventHandler(this, "chooseFileBtn_click");
  //Current File Label
  currentFile = new GLabel(this, 1280, 40, 900, 20);
  currentFile.setTextAlign(GAlign.LEFT, GAlign.BOTTOM);
  currentFile.setFont(new java.awt.Font("Monospaced", Font.ITALIC, 14));
  currentFile.setText("No File Selected...");
  currentFile.setOpaque(false);

  //Serial Devices Label
  serialDevicesLabel = new GLabel(this, 1160, 60, 200, 80);
  serialDevicesLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  serialDevicesLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  serialDevicesLabel.setText("Select Serial Port:");
  serialDevicesLabel.setOpaque(false);
  //Serial Devices DropList
  serialDevices = new GDropList(this, 1350, 88, 210, 100, 3);
  if (Serial.list().length == 0)
  {
    String[] deviceList = {"No available ports."}; 
    serialDevices.setItems(deviceList, 0);
  }
  else
  {
    serialDevices.setItems(Serial.list(), 0);
  }
  serialDevices.addEventHandler(this, "serialDevices_click1");

  //Baud Rate Label
  baudRateLabel = new GLabel(this, 1160, 120, 200, 50);
  baudRateLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  baudRateLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  baudRateLabel.setText("Baud Rate:");
  baudRateLabel.setOpaque(false);
  //Baud Rate TextBox
  baudRateTextBox = new GTextField(this, 1270, 125, 70, 30, G4P.SCROLLBARS_NONE);
  baudRateTextBox.setOpaque(true);
  baudRateTextBox.addEventHandler(this, "baudRateTextBox_change");

  //Print When Ready CheckBox
  printWhenReadyBox = new GCheckbox(this, 1360, 120, 200, 50);
  printWhenReadyBox.setIconAlign(GAlign.LEFT, GAlign.MIDDLE);
  printWhenReadyBox.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  printWhenReadyBox.setText("Print When Ready");
  printWhenReadyBox.setOpaque(false);
  printWhenReadyBox.addEventHandler(this, "printWhenReadyBox_clicked");

  //Infill Label
  infillLabel = new GLabel(this, 1390, 170, 80, 20);
  infillLabel.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  infillLabel.setFont(new Font(Font_Type, Font.PLAIN, 14));
  infillLabel.setText("Infill:");
  infillLabel.setOpaque(false);
  //Infill Slider
  infillSlider = new GSlider(this, 1350, 185, 160, 50, 10.0);
  infillSlider.setShowValue(true);
  infillSlider.setShowLimits(true);
  infillSlider.setLimits(0.50, 0.00, 1.00);
  infillSlider.setNbrTicks(100);
  infillSlider.setNumberFormat(G4P.DECIMAL, 2);
  infillSlider.setOpaque(false);
  infillSlider.addEventHandler(this, "qualitySlider_change");

  //Filament Label
  filamentLabel = new GLabel(this, 1370, 245, 140, 30);
  filamentLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  filamentLabel.setFont(new Font(Font_Type, Font.PLAIN, 14));
  filamentLabel.setText("Filament Diameter:");
  filamentLabel.setOpaque(false);
  //Filament Slider
  filamentSlider = new GSlider(this, 1350, 265, 160, 50, 10.0);
  filamentSlider.setShowValue(true);;
  filamentSlider.setShowLimits(true);
  filamentSlider.setLimits(2.37, 1.75, 3.0);
  filamentSlider.setNumberFormat(G4P.DECIMAL, 2);
  filamentSlider.setOpaque(false);
  filamentSlider.addEventHandler(this, "filamentSlider_change");
  
  //X Label
  xLabel = new GLabel(this, 1155, 180, 80, 20);
  xLabel.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  xLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  xLabel.setText("X Area:");
  xLabel.setOpaque(false);
  //X TextBox
  xTextBox = new GTextField(this, 1240, 175, 70, 30, G4P.SCROLLBARS_NONE);
  xTextBox.setOpaque(true);
  xTextBox.addEventHandler(this, "areaTextfield_change");

  //Y Label
  yLabel = new GLabel(this, 1155, 230, 80, 20);
  yLabel.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  yLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  yLabel.setText("Y Area:");
  yLabel.setOpaque(false);
  //Y TextBox
  yTextBox = new GTextField(this, 1240, 225, 70, 30, G4P.SCROLLBARS_NONE);
  yTextBox.setOpaque(true);
  yTextBox.addEventHandler(this, "areaTextfield_change");

  //Z Label
  zLabel = new GLabel(this, 1155, 280, 80, 20);
  zLabel.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  zLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  zLabel.setText("Z Area:");
  zLabel.setOpaque(false);
  //Z TextBox
  zTextBox = new GTextField(this, 1240, 275, 70, 30, G4P.SCROLLBARS_NONE);
  zTextBox.setOpaque(true);
  zTextBox.addEventHandler(this, "areaTextfield_change");

  //Nozzle Label
  nozzleLabel = new GLabel(this, 1380, 330, 200, 20);
  nozzleLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  nozzleLabel.setFont(new Font(Font_Type, Font.PLAIN, 14));
  nozzleLabel.setText("Nozzle Diameter:");
  nozzleLabel.setOpaque(false);
  //Nozzle Slider
  nozzleSlider = new GSlider(this, 1350, 350, 160, 40, 10.0);
  nozzleSlider.setShowValue(true);
  nozzleSlider.setShowLimits(true);
  nozzleSlider.setLimits(0.6, 0.2, 1.0);
  nozzleSlider.setNumberFormat(G4P.DECIMAL, 2);
  nozzleSlider.setOpaque(false);
  nozzleSlider.addEventHandler(this, "nozzleSlider_change");

  //Layer Scale Label
  layerScaleLabel = new GLabel(this, 1200, 330, 200, 20);
  layerScaleLabel.setTextAlign(GAlign.LEFT, GAlign.LEFT);
  layerScaleLabel.setFont(new Font(Font_Type, Font.PLAIN, 14));
  layerScaleLabel.setText("Layer Scale:");
  layerScaleLabel.setOpaque(false);
  //Layer Scale Slider
  layerScaleSlider = new GSlider(this, 1160, 350, 160, 40, 10.0);
  layerScaleSlider.setShowValue(true);
  layerScaleSlider.setShowLimits(true);
  layerScaleSlider.setLimits(0.2, 0.1, 0.3);
  layerScaleSlider.setNumberFormat(G4P.DECIMAL, 2);
  layerScaleSlider.setOpaque(false);
  layerScaleSlider.addEventHandler(this, "sliderLayerScale_change");

  //Warm Up Button
  warmUpBtn = new GButton(this, 1160, 430, 110, 50);
  warmUpBtn.setFont(new Font(Font_Type, Font.PLAIN, 16));
  warmUpBtn.setText("Temperature Setting");
  warmUpBtn.addEventHandler(this, "warmUpBtn_click");

  //Homing Button
  homingBtn = new GButton(this, 1400, 430, 100, 50);
  homingBtn.setFont(new Font(Font_Type, Font.PLAIN, 16));
  homingBtn.setText("Homing");
  homingBtn.addEventHandler(this, "homingBtn_click");

  //Connect Button
  connectBtn = new GButton(this, 1280, 430, 100, 50);
  connectBtn.setFont(new Font(Font_Type, Font.PLAIN, 16));
  connectBtn.setText("Connect to Printer");
  connectBtn.addEventHandler(this, "connectBtn_click");

  //Start Button

  startPrintBtn = new GButton(this, 1160, 500, 100, 40);
  startPrintBtn.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  startPrintBtn.setText("Start");
  startPrintBtn.addEventHandler(this, "startPrintBtn_click");

  //Pause Button
  pausePrintBtn = new GButton(this, 1280, 500, 100, 40);
  pausePrintBtn.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  pausePrintBtn.setText("Pause");
  pausePrintBtn.addEventHandler(this, "pausePrintBtn_click");

  //Cancel Button
  cancelPrintBtn = new GButton(this, 1400, 500, 100, 40);
  cancelPrintBtn.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  cancelPrintBtn.setText("Cancel");
  cancelPrintBtn.addEventHandler(this, "cancelPrintBtn_click");

  //Console Button
  //consoleBtn = new GButton(this, 1400, 700, 100, 40);
  //consoleBtn.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  //consoleBtn.setText("Console");
  //consoleBtn.addEventHandler(this, "consoleBtn_click");

  //Status Label
  statusLabel = new GLabel(this, 1160, 550, 400, 100);
  statusLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  statusLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  statusLabel.setText("Status:");
  statusLabel.setOpaque(false);

  //Rendering Label
  renderLabel = new GLabel(this, 1280, 670, 250, 30);
  renderLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  renderLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  renderLabel.setText("Render Controls");
  renderLabel.setOpaque(false);
  
  
  //Right Arrow
  rightArrowbtn = new GButton(this, 1365, 780, 42, 36);
  rightArrowbtn.setIcon("ArrowRight.png", 1, GAlign.EAST, GAlign.RIGHT, GAlign.MIDDLE);
  rightArrowbtn.addEventHandler(this, "rightArrowbtn_click1");
  //Up Arrow
  upArrowbtn = new GButton(this, 1325, 740, 40, 41);
  upArrowbtn.setIcon("ArrowUp.png", 1, GAlign.EAST, GAlign.RIGHT, GAlign.MIDDLE);
  upArrowbtn.addEventHandler(this, "upArrowbtn_click1");
  //Left Arrow
  leftArrowbtn = new GButton(this, 1280, 780, 44, 36);
  leftArrowbtn.setIcon("ArrowLeft.png", 1, GAlign.EAST, GAlign.RIGHT, GAlign.MIDDLE);
  leftArrowbtn.addEventHandler(this, "leftArrowbtn_click1");
  //Down Arrow
  downArrowbtn = new GButton(this, 1325, 810, 40, 40);
  downArrowbtn.setIcon("ArrowDown.png", 1, GAlign.EAST, GAlign.RIGHT, GAlign.MIDDLE);
  downArrowbtn.addEventHandler(this, "downArrowbtn_click1");

  //Choose File Window
  inputWindow = GWindow.getWindow(this, "Choose STL File", 0, 0, 280, 120, JAVA2D);
  inputWindow.noLoop();
  inputWindow.addDrawHandler(this, "win_draw1");
  fileTextBox = new GTextField(inputWindow, 10, 20, 160, 30, G4P.SCROLLBARS_NONE);
  fileTextBox.setPromptText("Choose File...");
  fileTextBox.setOpaque(true);
  fileTextBox.addEventHandler(this, "fileTextBox_change");
  searchFileBtn = new GButton(inputWindow, 180, 20, 80, 30);
  searchFileBtn.setText("Browse...");
  searchFileBtn.addEventHandler(this, "searchFileBtn_click");
  //gcodeTextBox = new GTextArea(inputWindow, 10, 80, 280, 220, G4P.SCROLLBARS_VERTICAL_ONLY);
  //gcodeTextBox.setOpaque(true);
  //gcodeTextBox.addEventHandler(this, "gcodeTextBox_change");
  cancelInputBtn = new GButton(inputWindow, 179, 80, 80, 30);
  cancelInputBtn.setText("Cancel");
  cancelInputBtn.addEventHandler(this, "cancelInputBtn_click");
  confirmBtn = new GButton(inputWindow, 10, 80, 80, 30);
  confirmBtn.setText("Confirm");
  confirmBtn.addEventHandler(this, "confirmBtn_click");
  inputWindow.loop();
  inputWindow.setVisible(false);

  //Warm Up Settings Window
  warmupWindow = GWindow.getWindow(this, "Temperature Settings", 100, 100, 400, 250, JAVA2D);
  warmupWindow.noLoop();
  warmupWindow.addDrawHandler(this, "warmupWin_draw");
  //Head Temp
  headTempLabel = new GLabel(warmupWindow, 10, 10, 350, 30);
  headTempLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  headTempLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  headTempLabel.setText("Head Temperature:");
  headTempLabel.setOpaque(false);
  headTempTextBox = new GTextField(warmupWindow, 188, 10, 50, 30, G4P.SCROLLBARS_NONE);
  headTempTextBox.setOpaque(true);
  headTempTextBox.addEventHandler(this, "tempTextBox_change");
  //Bed Temp
  bedTempLabel = new GLabel(warmupWindow, 10, 100, 200, 30);
  bedTempLabel.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  bedTempLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  bedTempLabel.setText("Bed Temperature:");
  bedTempLabel.setOpaque(false);
  bedTempTextBox = new GTextField(warmupWindow, 188, 100, 50, 30, G4P.SCROLLBARS_NONE);
  bedTempTextBox.setOpaque(true);
  bedTempTextBox.addEventHandler(this, "tempTextBox_change");
  //Confirm
  warmupconfirmBtn = new GButton(warmupWindow, 10, 200, 80, 30);
  warmupconfirmBtn.setFont(new Font(Font_Type, Font.PLAIN, 16));
  warmupconfirmBtn.setText("Confirm");
  warmupconfirmBtn.addEventHandler(this, "warmupconfirmBtn_click");
  //Cancel
  warmupcancelBtn = new GButton(warmupWindow, 310, 200, 80, 30);
  warmupcancelBtn.setFont(new Font(Font_Type, Font.PLAIN, 16));
  warmupcancelBtn.setText("Cancel");
  warmupcancelBtn.addEventHandler(this, "warmupcancelBtn_click");
  warmupWindow.loop();

  ////Log Window
  //logWindow = GWindow.getWindow(this, "Console Log", 0, 0, 300, 350, JAVA2D);
  //logWindow.noLoop();
  //logWindow.addDrawHandler(this, "logWin_draw1");
  //logTextBox = new GTextArea(logWindow, 10, 10, 290, 290, G4P.SCROLLBARS_BOTH);  //should have scrollbar
  //logTextBox.setOpaque(true);
  ////Close logWindow button
  //logCloseBtn = new GButton(logWindow, 10, 310, 80, 30);
  //logCloseBtn.setFont(new Font(Font_Type, Font.PLAIN, 16));
  //logCloseBtn.setText("Close");
  //logCloseBtn.addEventHandler(this, "logCloseBtn_click");
  //logWindow.loop();

  //Error Window
  errorWindow = GWindow.getWindow(this, "ERROR", 0, 0, 500, 220, JAVA2D);
  errorWindow.noLoop();
  errorWindow.addDrawHandler(this, "errorWin_draw");
  errorHeadingLabel = new GLabel(errorWindow, 10, 10, 480, 40);
  errorHeadingLabel.setTextAlign(GAlign.CENTER, GAlign.MIDDLE);
  errorHeadingLabel.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  errorHeadingLabel.setText("ERROR");
  errorHeadingLabel.setOpaque(false);
  errorTextbox = new GTextField(errorWindow, 10, 50, 480, 100, G4P.SCROLLBARS_VERTICAL_ONLY);
  errorTextbox.setFont(new Font(Font_Type, Font.PLAIN, Font_Size));
  errorTextbox.setOpaque(true);
  //Close Error Window
  errorCloseBtn = new GButton(errorWindow, 440, 170, 50, 30);
  errorCloseBtn.setFont(new Font(Font_Type, Font.PLAIN, 16));
  errorCloseBtn.setText("OK");
  errorCloseBtn.addEventHandler(this, "errorCloseBtn_click");
  errorWindow.loop();
}

                                       //Variables:

//Variables for 3D printer
boolean printWhenReady;
float infill;          // infill % (0 - 1)
String filePath;
int xArea;             //Range 1-200 for build area in x, y, z
int yArea;
int zArea;
float nozzleDiameter;  //range 0-1
float layerScale;       //range range 0 - 0.4

GButton startPrintBtn;

GButton pausePrintBtn;

GButton cancelPrintBtn;

//Choose File
GButton chooseFileBtn;
GLabel currentFile;
String STLFile;
String fileName;

//Serial Devices
GLabel serialDevicesLabel;
GDropList serialDevices;
String port;

//Baud Rate
Integer baudRate;
GLabel baudRateLabel;
GTextField baudRateTextBox;

GCheckbox printWhenReadyBox;

//Infill
GSlider infillSlider;
GLabel infillLabel;

//XYZ
GTextField xTextBox;
GTextField yTextBox;
GTextField zTextBox;
GLabel xLabel;
GLabel yLabel;
GLabel zLabel;

//Filament Diameter
GSlider filamentSlider;
GLabel filamentLabel;
float filamentDiameter;

//Nozzle
GSlider nozzleSlider;
GLabel nozzleLabel;

//Layer
GSlider layerScaleSlider;
GLabel layerScaleLabel;

GButton warmUpBtn;

GButton homingBtn;

GButton connectBtn;

//Log Window
//GButton consoleBtn;
//GWindow logWindow;
//GTextArea logTextBox;
//GButton logCloseBtn;

GLabel statusLabel;

GLabel renderLabel;

GButton rightArrowbtn;
GButton upArrowbtn;
GButton leftArrowbtn;
GButton downArrowbtn;

//Choose File Window
GWindow inputWindow;
GTextField fileTextBox;
GButton searchFileBtn;
//GTextArea gcodeTextBox;
GButton cancelInputBtn;
GButton confirmBtn;

//Warm Up Settings Window
GWindow warmupWindow;
GLabel headTempLabel;
GTextField headTempTextBox;
GLabel bedTempLabel;
GTextField bedTempTextBox;
GButton warmupconfirmBtn;
GButton warmupcancelBtn;
Integer headTemp;
Integer bedTemp;

//Error Popup
GWindow errorWindow;
GLabel errorHeadingLabel;
GTextField errorTextbox;
GButton errorCloseBtn;

//Font Settings
String Font_Type = "Sans-Serif";
Integer Font_Size = 18;

//Printing Codes for Preheating
String [] homing = {"G28 \r\n"};  // normal homing
String [] cooldownHoming = {"M104 S0 \r\n", "M140 S0 \r\n", "G28 X0 \r\n", "G28 Y0 \r\n"}; // When print job is complete or aborted - "after printing, we should only move the x/y axis out of the way. Moving the head down could hit the printed object"

// Status Label and state of the program

private enum ConnectState        { DISCONNECTED, CONNECTED }
private enum PrinterState        { IDLE, PRINTING, PAUSE}
private enum SliceState          { NO_FILE, NOT_SLICED, SLICED}

// default startup states
private ConnectState stateConnect = ConnectState.DISCONNECTED;
private PrinterState statePrinter = PrinterState.IDLE;
private SliceState stateSlice = SliceState.NO_FILE;

private void updateState()
{
    // Slice State
    if (STLFile == null || STLFile.length() <= 0)
        stateSlice = SliceState.NO_FILE;                       // no file string loaded
    else if (gcode != null && gcode.size() > 0)
        stateSlice = SliceState.SLICED;                        // stl is sliced
    else if (gcode != null && gcode.size() <= 0)
        stateSlice = SliceState.NOT_SLICED;                   // stl is not sliced
    // Connection State
    if (devControl.serialConnected())
        stateConnect = ConnectState.CONNECTED;                // connected to the serial port
    else if (!devControl.serialConnected())
        stateConnect = ConnectState.DISCONNECTED;
    // Print State
    if (devControl.isJobRunning() && !devControl.pauseRequested() && devControl.serialConnected())    // maybe remove serialConnect
        statePrinter = PrinterState.PRINTING;                 // activly printing
    else if (devControl.pauseRequested())
        statePrinter = PrinterState.PAUSE;                    // printing paused
    else if (!devControl.isJobRunning() || !devControl.pauseRequested() || devControl.serialConnected())  // can it just be if !devControl.isJobRunning() ?  // maybe remove serialConnect
        statePrinter = PrinterState.IDLE;                     // printer is idle
}

// Updates the status label with the corresponding state
private void updateStatusLabel()
{
    updateState();
    
    // Print When Ready check
    if (printWhenReady && !devControl.isJobRunning() && devControl.serialConnected() && gcode != null && gcode.size() > 0)
    {
      println("PrintWhenReady turned on -> auto-calling startPrintJob() now");
      devControl.startPrintJob(gcode);
    }
    
    String[] lblStatus = new String[3];
    switch (stateConnect)
    {
        case DISCONNECTED: lblStatus[0] = "Disconnected";
                                        break;
        case CONNECTED:    lblStatus[0] = "Connected";
                                        break;
        default:                        lblStatus[0] = "ERROR";
    }
    switch (statePrinter)
    {
        case IDLE:      lblStatus[1] = "Idle";
                                     break;
        case PRINTING:  lblStatus[1] = "Printing";
                                     break;
        case PAUSE:     lblStatus[1] = "Paused";
                                     break;
        default:                     lblStatus[1] = "ERROR";
    }
    switch (stateSlice)
    {
        case NO_FILE:    lblStatus[2] = "No STL file selected";
                                    break;
        case NOT_SLICED: lblStatus[2] = "Waiting to be sliced";
                                    break;
        case SLICED:     lblStatus[2] = "G-code generated for " + fileName;
                                    break;
        default:                    lblStatus[3] = "ERROR";
    }
    statusLabel.setText("      Status\nFile: " + lblStatus[2] + " \nDevice: " + lblStatus[0] + "\nPrinter: " + lblStatus[1]);
}



// This will be done by Slicing team now in their GCode generation
//    *** We need to manually pass "Cooling" code if print job is cancelled/aborted -> M140 S0 and M104 S0
//String [] heatingbedCode = {"M140 S0 \r\n"};
//String [] heatingbedwaitCode = {"M190 S0"};
//String [] heatingheadCode = {"M104 S0 \r\n"};
//String [] heatingheadwaitCode = {"M109 S0"};