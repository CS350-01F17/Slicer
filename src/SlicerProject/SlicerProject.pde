/*
SlicerProject.pde
 This Sketchbook tab contains the main code that runs the entire program. 
 For more information, view the accompanying READMEs located throughout the project. 
 Authors: Andrew Figueroa, Paul Canada, Christopher Iossa
 */

// Global runtime variables
ArrayList<Line> toDraw = null;
int currentLine = 0;
boolean drawLayer; 

//This function is automatically called when the project is run/executed.
// Once this function finished executing, the draw function is called (repeatedly).
void setup() {

  String stlDir ="%Model Directory%"; //directory path to directory where 3D models are stored 
  String stlPath = "%STLPATH%"; //filename (or relative path from %stlDir%) of desired STL file 
  String gcodeDir = "%GCODE DIRECTORY"; //directory path to directory where gcode files should be stored, file will be named %stlPath%.gcode

  drawLayer = true; //true to draw layer, false to skip draw
  int layerToDraw = 0; // layer number to draw on the screen if drawLayer = true

  float layerHeight = .15; //a value from 0.3 (low quality) to 0.1 (high quality) specifying layer height
  float infill = .1; //infill percentage 


  // Parse the STL file.
  STLParser parser = new STLParser( stlDir + stlPath);

  ArrayList<Facet> facets = parser.parseSTL();

  // Slice object; includes output for timing the slicing procedure.
  long startTime = millis();
  Slicer slice = new Slicer(facets, layerHeight, infill);
  ArrayList<Layer> layers = slice.sliceLayers();

  ArrayList<String> gCode = slice.createGCode(layers, %extruderTemp%, %bedTemp%); //extruder should be between 200 and 210 for PLA, ABS should be between 220 and 240. Bed temp for PLA should be between 40 and 60 and 100 and 120 for ABS 

  String[] gCodeArr = new String[gCode.size()];
  gCodeArr = gCode.toArray(gCodeArr);
  int nameStart = stlPath.lastIndexOf('\\');
  if (nameStart == -1)
  {
    nameStart = stlPath.lastIndexOf('/');
    
    if (nameStart == -1)
    {
      nameStart = 0;
    }
  }
  
  int nameEnd = stlPath.lastIndexOf('.');
  if (nameEnd == -1)
  {
    nameEnd = stlPath.length();
  }

  String gCodeName = stlPath.substring(nameStart, nameEnd);
  
  saveStrings(gcodeDir + gCodeName + ".gcode", gCodeArr);
  

  long endTime = millis();
  println("\nTotal time: " + (endTime - startTime) + "ms");
  println("Total number of layers: " + layers.size());


  // Reference to the designated layer for drawing in the frame.
  ArrayList<Line> lines = layers.get(layerToDraw).getCoordinates();
  toDraw = lines;


  println("Num lines on drawn layer (" + layerToDraw + "): " + lines.size());
  size(800, 800); // Set the size of the drawing frame.
  frameRate(60); // Decrease to change speed that the layer is drawn at (min 1, max 60)
}

//After the setup function finishes, this function is called repeatedly until the
// program exits.
//Depending on how the project proceeds, we may not use this function, and instead
// treat the setup function as if it were similar to a main function in C/C++/Java.
void draw() {
  if (drawLayer)
  {
    if (currentLine < toDraw.size())
    {
      Line li = toDraw.get(currentLine);

      // Scale the coordinates so they are visible on the draw screen.
      li.x1 *= 10;
      li.y1 *= 10;
      li.x2 *= 10;
      li.y2 *= 10;

      li.x1 += 400;
      li.y1 += 400;
      li.x2 += 400;
      li.y2 += 400;

      // Check if the line's toolpath travel boolean is set.
      // If so, draw that line as blue. 
      if (li.isTravel)
      {
        stroke(0, 0, 255); // Blue
      }
      // Otherwise, draw it as black.
      else
      {
        stroke(0); // Black
      }

      line(li.x1, li.y1, li.x2, li.y2);
      currentLine++;
    }
  }
}