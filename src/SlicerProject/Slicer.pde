/* //<>// //<>//
 Slicer.pde
 
 This Sketchbook tab holds the definition and implementation of the Slicer class.
 
 The Slicer class represents the controller for the slicing process that converts a 3D
 model into a series of 2D layers. Methods are provided to turn Facets that make up a
 3D model into a list of layers, and to process the layers into RepRap GCode that provides
 instructions to a 3D printer on how to physically reproduce the 3D model.
 
 TODO: Currently, only the most basic slicing has been implemented. Walls, travels, and
 GCode creation have not yet been implemented.
 
 Authors:
 Andrew Figueroa, Aaron Finnegan, Chris Iossa (Slicing Team)
 */

import java.util.Arrays;
import java.util.Collection;
import java.util.NavigableMap;
import java.util.TreeMap;
import java.util.HashSet;
import java.util.Comparator;

public class Slicer
{
  private TreeMap<Float, ArrayList<Facet>> lowVSort;
  private TreeMap<Float, ArrayList<Facet>> highVSort;
  private float extrudedAmount;
  private float xInit; //used to represent the x coordinate of the extruder before a layer is printed, initially 0
  private float yInit; //used to represent the y coordinate of the extruder before a layer is printed, initially 0
  private final float layerHeight;
  private final float infillPercentage;
  private final float topBottomSize;
  private final float filamentDiam;
  private final int travelSpeed;
  private final int printSpeed;
  private final int buildAreaX;
  private final int buildAreaY;
  private final int buildAreaZ;
  private final float nozzleDiam;


  /**
   * Constructor
   *
   * @param  facets  A representation of the facets that make up the 3D model
   * @param  layerHeight  The desired z-height of each layer in the sliced object. 
   * Must be > 0.0, otherwise, it is set to 1.5
   * @param  infill  Percentage of the inside part of the object that should be
   * filled with material. Should be between 0 and 1
   */
  public Slicer(ArrayList<Facet> facets, float layerHeight, float infill)
  {
    //validate and set layer height
    if (layerHeight <= 0.0)
    {
      layerHeight = .2;
    }
    this.layerHeight = layerHeight;

    //validate and set infill percentage
    if (infill > 1.0)
    {
      infill = 1.0;
    } else if (infill < 0.0)
    {
      infill = 0;
    }
    this.infillPercentage = infill;

    //TODO: get these six (five? - filamentDiam was not requested) values from the UI
    topBottomSize = 1.2; //thickness of solid top and bottom portions
    buildAreaX = 120;
    buildAreaY = 120;
    buildAreaZ = 120;
    nozzleDiam = 0.4;
    filamentDiam = 1.75;
    xInit=0;
    yInit=0;

    //TODO: calculate these based on print quality
    printSpeed = 2400; //40 mm/s
    travelSpeed = 3000; //50 mm/s

    extrudedAmount = 0.0;

    //create "psuedo-multimap" sorted low to high by the lowest z-height
    lowVSort = new TreeMap<Float, ArrayList<Facet>>();
    for (Facet f : facets)
    {
      Float minZ = getLowestZVertex(f).z;
      ArrayList<Facet> sameMinZ = lowVSort.get(minZ);
      if (sameMinZ == null)
      {
        lowVSort.put(minZ, sameMinZ = new ArrayList<Facet>());
      }
      sameMinZ.add(f);
    }

    //create "psuedo-multimap" sorted low to high by the highest z-height
    highVSort = new TreeMap<Float, ArrayList<Facet>>();
    for (Facet f : facets)
    {
      Float maxZ = getHighestZVertex(f).z;
      ArrayList<Facet> sameMaxZ = highVSort.get(maxZ);
      if (sameMaxZ == null)
      {
        highVSort.put(maxZ, sameMaxZ = new ArrayList<Facet>());
      }
      sameMaxZ.add(f);
    }
  }


  /**
   * Slices the 3D model to a printable representation at intervals that match layerHeight
   *
   * This method completely slices the 3D model given at object creation to its printable
   * representation. This includes determining the intersections of the 3D model, adding
   * walls, adding infill, and determining necessary travels for each layer.
   *
   * @return  An ArrayList<Layer> of the layers that make up the printable representation
   * of the 3D model.
   */
  public ArrayList<Layer> sliceLayers()
  {
    float highestPos = highVSort.lastEntry().getKey();
    final float START_OFFSET = .00001;
    float lowestPos = lowVSort.firstEntry().getKey() + START_OFFSET;

    ArrayList<Layer> layers = new ArrayList<Layer>();
    layers.ensureCapacity((int)((highestPos - lowestPos) / layerHeight) + 1);

    //TODO: validate model size (should be smaller than build area)
    boolean horizontal = false;
    for (float pos = lowestPos; pos < highestPos; pos += layerHeight)
    { 
      Layer currLayer = sliceLayer(pos);

      if (pos < (lowestPos + topBottomSize) || pos > highestPos - topBottomSize)
      {
        if (horizontal)
        {
          currLayer = addXInfill(currLayer, 1.0);
        } else
        {
          currLayer = addYInfill(currLayer, 1.0);
        }
      } else
      {
        if (horizontal)
        {
          currLayer = addXInfill(currLayer, infillPercentage);
        } else
        {
          currLayer = addYInfill(currLayer, infillPercentage);
        }
      }
      horizontal = !horizontal;

      //TODO: add walls

      //TODO: compute travels
      currLayer.setCoordinates( getToolPath(currLayer) );
      layers.add(currLayer);
    }

    return layers;
  }


  /**
   * Gets the RepRap GCode that can be used to print the 3D model
   *
   * This method uses the information in layers to create RepRap GCode commands that can
   * be sent to a compatable 3D printer in order to print the 3D model represented by
   * the given layers.
   *
   * @param  layers  An ArrayList<Layer> of layers to be printed
   * @param  extTemp Int representing temperature to set extruder to
   * @param  bedTemp Int representing temperature to set bed to
   * @return  An ArrayList<String> of RepRap GCode commands ready to be sent to a printer
   */
  public ArrayList<String> createGCode(ArrayList<Layer> layers, int extTemp, int bedTemp)
  {
    ArrayList<String> gCode = null;
    if (layers == null)  return null;

    gCode = new ArrayList<String>();

    //calculate total number of expected GCode commands
    int numLines = 0;
    for (Layer la : layers)
    {
      numLines += la.getCoordinates().size();
    }

    //a comment for each layer, layer-to-layer travel + 3: header, startGCode, endGCode
    final int numExtraStrings = layers.size() * 2 + 3;

    gCode.ensureCapacity(numLines + numExtraStrings);

    String gCodeHeader = ";FLAVOR:RepRap\r\n;Number of layers:" + layers.size() + "\r\n" +
      ";generated by CS350 Slicer - https://github.com/CS350-01F17/Slicer";

    //TEMP: works for afig's test printer
    String startGCode = 
      "M140 S" +bedTemp +" \r\n" + //set bed temperatur (bedTemp deg C)
      "M190 S" +bedTemp +" \r\n" + //wait until this bed temperature is reached
      "M104 S" +extTemp +" \r\n" + //set extruder temperature (extTemp deg C)
      "M109 S" +extTemp +" \r\n" + //wait until this extruder temperature is reached
      
      "G90 ; use absolute positioning\r\n" + 
      "G28 ; home all axes"; 

    gCode.add(gCodeHeader);
    gCode.add(startGCode);

    float currZ = 0.0;
    for (int i = 0; i < layers.size(); i++)
    {
      String layerComment = ";Layer: " + i;
      gCode.add(layerComment);

      currZ += layerHeight;

      String layerTravel = "G0 Z" + currZ;
      gCode.add(layerTravel);

      ArrayList<String> layerCommands = layerToGCode(layers.get(i), buildAreaX/2, buildAreaY/2, printSpeed, travelSpeed);

      gCode.addAll(layerCommands);
    }

    //TEMP: works for afig's test printer
    String endGCode = 
      "M104 S0 ; turn off hotend heater\r\n" +
      "M140 S0 ; turn off bed heater\r\n" +
      "G91 ; switch to relative coordinates\r\n" +
      "G1 E-2 F300 ; retract the filament a bit before lifting the nozzle to release some of the pressure\r\n" +
      "G1 Z1 ; raise Z 1mm from current position\r\n" +
      "G1 E-2 F300 ; retract filament even more\r\n" +
      "G90 ; switch back to absolute coordinates\r\n" +
      "G1 X20 ; move X axis closer to tower\r\n" +
      "G1 Y115 ; move bed forward for easier part removal\r\n" +
      "M84 ; disable motors\r\n" +
      "G4 S300 ; keep fan running for 300 seconds to cool hotend and allow the fan to be turned off\r\n" +
      "M106 S1 ; turn off fan";

    gCode.add(endGCode);

    return gCode;
  }


  /**
   * Slices the given layer
   *
   * This method determines the facets that intersect the plane at the given z-height,
   * creates lines between the two intersections of each facet, and places them into a 
   * Layer object which is returned
   *
   * @param  ZPos  The height of the layer to slice
   * @return  A Layer object that represents the 2-dimensional intersections of the model
   * at the given height.
   */
  public Layer sliceLayer(float zPos)
  {
    //create sub-maps containg only the facets that intersect the current z-height
    NavigableMap<Float, ArrayList<Facet>> lowerFacets = lowVSort.headMap(zPos, true);
    NavigableMap<Float, ArrayList<Facet>> upperFacets = highVSort.tailMap(zPos, true);

    //get a HashSet<Facet> of the facets that are in both submaps
    HashSet<Facet> allLowerFacets = extractFacets(lowerFacets.values());
    HashSet<Facet> allUpperFacets = extractFacets(upperFacets.values());
    allLowerFacets.retainAll(allUpperFacets);
    HashSet<Facet> intersectingFacets = allLowerFacets;

    //create ArrayList to hold lines which represent the intersections at zPos
    ArrayList<Line> lines = new ArrayList<Line>();
    lines.ensureCapacity(intersectingFacets.size());

    //this comparator compares the z value of two PVectors
    PVectorZComparator compZ = new PVectorZComparator();

    for (Facet f : intersectingFacets)
    {
      /* Except for the case where there is only one point at zPos, the algorithm uses 
       linear interpolation to calculate the two points where the lines of the facet
       intersect with the plane at zPos. It then creates a line with these two points
       as the line's end points. See https://en.wikipedia.org/wiki/Linear_interpolation
       The linear interpolation is performed using the PVector.lerp() function for
       simplicity. However, all the function does is: start + (stop-start) * amount
       for each of the three floats in a PVector. amount is determined by finding the
       percentage of the facet's line that is "cut off" by the current plane. */

      int numHigherVerts = numVerteciesAbove(f, zPos);

      if (numHigherVerts == 0) //single point on current plane, 2 below
      {
        PVector p = getHighestZVertex(f);
        lines.add(new Line(p.x, p.y, p.x, p.y, false));
      } else if (numHigherVerts == 1) //1 point above, 2 points below or on current plane 
      {
        PVector[] sortedVerts = f.getVerticies(); //not sorted until next line
        Arrays.sort(sortedVerts, compZ);

        //calculate first point
        float liFactor1 = (zPos - sortedVerts[0].z) / (sortedVerts[2].z - sortedVerts[0].z); 
        PVector p1 = PVector.lerp(sortedVerts[0], sortedVerts[2], liFactor1);

        //calculate second point
        float liFactor2 = (zPos - sortedVerts[1].z) / (sortedVerts[2].z - sortedVerts[1].z); 
        PVector p2 = PVector.lerp(sortedVerts[1], sortedVerts[2], liFactor2);

        //create line
        lines.add(new Line(p1.x, p1.y, p2.x, p2.y, false));
      } else //2 points above, 1 point below or on current plane
      {
        PVector[] sortedVerts = f.getVerticies(); //not sorted until next line
        Arrays.sort(sortedVerts, compZ);

        //calculate first point
        float liFactor1 = (zPos - sortedVerts[0].z) / (sortedVerts[1].z - sortedVerts[0].z);
        PVector p1 = PVector.lerp(sortedVerts[0], sortedVerts[1], liFactor1);

        //calculate second point
        float liFactor2 = (zPos - sortedVerts[0].z) / (sortedVerts[2].z - sortedVerts[0].z);
        PVector p2 = PVector.lerp(sortedVerts[0], sortedVerts[2], liFactor2);

        //create line
        lines.add(new Line(p1.x, p1.y, p2.x, p2.y, false));
      }
    }

    return new Layer(lines, zPos);
  }


  /**
   * Gets RepRap GCode that prints the given Layer
   *
   * This method interpets a single layer object and creates GCode that can be used
   * to print this layer on a RepRap compatable 3D printer
   *
   * @param  layer  The layer to create GCode instructions for
   * @param  extrudedAmount  the amount of filament extruded so far; modified in method
   * @param  xOff  x-offset required from model to printer
   * @param  yOff  y-offset required from model to printer
   * @param  pSpeed  print speed, measured in mm/min
   * @param  tSpeed  travel speed, measure in mm/min
   * @return  An ArrayList<String> of GCode commands that will print the given layer
   */
  private ArrayList<String> layerToGCode(Layer l, float xOff, float yOff, float pSpeed, float tSpeed)
  {
    ArrayList<String> layerGCode = null;
    if (l == null) return null;

    layerGCode = new ArrayList<String>();
    layerGCode.ensureCapacity(l.getCoordinates().size());

    //travel to the first point in the layer
    if (l.getCoordinates().size() > 0)
    {
      Line li = l.getCoordinates().get(0);
      String firstCommand = "G0 F"+ tSpeed + " X" + (li.x1 + xOff) + " Y" + (li.y1 + yOff);
      layerGCode.add(firstCommand);
    }


    boolean wasTravelling = true;
    for (Line li : l.getCoordinates())
    {
      String command = "";

      if (li.isTravel)
      {
        if (wasTravelling)
        {
          command += "G0 X" + (li.x2 + xOff) + " Y" + (li.y2 + yOff);
        } else
        {
          command += "G0 F" + tSpeed + " X" + (li.x2 + xOff) + " Y" + (li.y2 + yOff);
          wasTravelling = true;
        }
      } else
      {
        /* Simple geometry: a printed line is a rectangular prism; the filament a cylinder.
         Find the volume of a printed line, and use that to determine the necessary 
         height of the cylinder (i.e. length of filament) that matches that volume.   */
        float lineVol = layerHeight * nozzleDiam * dist(li.x1, li.y1, li.x2, li.y2);
        //println("layerToGCode(): LineVol: " + lineVol + " for Line: [" + (li.x1 + xOff) +
        //        ", " + (li.y1 + yOff) + ", " + (li.x2 + xOff) + ", " + (li.y2 + yOff) + "]" + "  dist: " + dist(li.x1, li.y1, li.x2, li.y2));
        if (lineVol != 0)
        {
          //println("\tAmount added: " + (lineVol / (float)(Math.PI * Math.pow(filamentDiam, 2))));
          extrudedAmount += (float) lineVol / (Math.PI * Math.pow(filamentDiam / 2, 2));
        }

        if (wasTravelling)
        {
          command += "G1 F" + pSpeed + " X" + (li.x2 + xOff) + " Y" + (li.y2 + yOff) + " E" + extrudedAmount;
          wasTravelling = false;
        } else
        {
          command += "G1 X" + (li.x2 + xOff) + " Y" + (li.y2 + yOff) + " E" + extrudedAmount;
        }
      }

      layerGCode.add(command);
    }
    return layerGCode;
  }


  /**
   * Adds horizontal structural infill to the given layer
   *
   * This method adds Line objects to the given Layer that represent infill. The
   * given layer must represent a closed figure. If a non-closed figure is
   * identified, then no infill is added for invalid y-pos. An infill percentage of
   * 1 will result in a solid layer (useful for bottom and top layers)
   *
   * @param  layer  The Layer object to add horizontal infill to
   * @param  infillPercentage  Amount of infill to add to the layer (0 to 1)
   * @return The layer object with infill added
   */
  private Layer addXInfill(Layer layer, float infill)
  {
    if (layer == null || infill == 0.0)
    {
      return layer;
    }

    ArrayList<Line> lines = layer.getCoordinates();

    //create "psuedo-multimap" sorted low to high by the lowest y-value
    TreeMap<Float, ArrayList<Line>> lowLSort = new TreeMap<Float, ArrayList<Line>>();
    for (Line l : lines)
    {
      if (l.y1 != l.y2) //do not include horizontal lines
      {
        Float minY = min(l.y1, l.y2);
        ArrayList<Line> sameMinY = lowLSort.get(minY);
        if (sameMinY == null)
        {
          lowLSort.put(minY, sameMinY = new ArrayList<Line>());
        }
        sameMinY.add(l);
      }
    }

    //create "psuedo-multimap" sorted low to high by the highest y-value
    TreeMap<Float, ArrayList<Line>> highLSort = new TreeMap<Float, ArrayList<Line>>();
    for (Line l : lines)
    {
      if (l.y1 != l.y2) //do not include horizontal lines
      {
        Float maxY = max(l.y1, l.y2);
        ArrayList<Line> sameMaxY = highLSort.get(maxY);
        if (sameMaxY == null)
        {
          highLSort.put(maxY, sameMaxY = new ArrayList<Line>());
        }
        sameMaxY.add(l);
      }
    }


    int numScanLines = (int)(buildAreaY / nozzleDiam);
    int numDrawnLines = (int) (numScanLines * infill);
    float interval = numScanLines / numDrawnLines * nozzleDiam;

    float minY = getMinY(layer);
    float maxY = getMaxY(layer);

    for (float currScan = minY; currScan < maxY; currScan += interval)
    {
      NavigableMap<Float, ArrayList<Line>> lowerLines = lowLSort.headMap(currScan, true);
      NavigableMap<Float, ArrayList<Line>> upperLines = highLSort.tailMap(currScan, true);

      //get a HashSet<Line> of the lines that are in both submaps
      HashSet<Line> allLowerLines = extractLines(lowerLines.values());
      HashSet<Line> allUpperLines = extractLines(upperLines.values());
      allLowerLines.retainAll(allUpperLines);
      HashSet<Line> ixLines = allLowerLines;
      int numLines = ixLines.size();


      if (numLines % 2 != 0)
      {
        println("Slicer.addInfill(): Non-closed figure at layer height: "+ layer.zHeight +
          " and yPos: " + currScan);
      } else
      {
        //sort lines by their mininum x value
        ArrayList<Line> sortByMinX = new ArrayList<Line>(ixLines);
        sortByMinX.sort(new LineMinXComparator());

        Float x1 = null;
        for (Line l : sortByMinX)
        {
          //start + (stop-start) * amount
          float liFactor = (currScan - l.y1) / (l.y2 - l.y1);

          if (x1 == null)
          {
            //calculate first point
            x1 = (l.x2 - l.x1) * liFactor + l.x1;
          } else
          {
            //calculate second point
            Float x2 = (l.x2 - l.x1) * liFactor + l.x1;

            //add travel to layer
            layer.addLine(new Line(x1, currScan, x2, currScan, false));

            x1 = null;
          }
        }
      }
    }
    return layer;
  }

  /**
   * Adds vertical structural infill to the given layer
   *
   * This method adds Line objects to the given Layer that represent infill. The
   * given layer must represent a closed figure. If a non-closed figure is
   * identified, then no infill is added for invalid y-pos. An infill percentage of
   * 1 will result in a solid layer (useful for bottom and top layers)
   *
   * @param  layer  The Layer object to add vertical infill to
   * @param  infillPercentage  Amount of infill to add to the layer (0 to 1)
   * @return The layer object with infill added
   */
  private Layer addYInfill(Layer layer, float infill)
  {
    if (layer == null || infill == 0.0)
    {
      return layer;
    }

    ArrayList<Line> lines = layer.getCoordinates();

    //create "psuedo-multimap" sorted low to high by the lowest y-value
    TreeMap<Float, ArrayList<Line>> lowLSort = new TreeMap<Float, ArrayList<Line>>();
    for (Line l : lines)
    {
      if (l.x1 != l.x2) //do not include vertical lines
      {
        Float minX = min(l.x1, l.x2);
        ArrayList<Line> sameMinX = lowLSort.get(minX);
        if (sameMinX == null)
        {
          lowLSort.put(minX, sameMinX = new ArrayList<Line>());
        }
        sameMinX.add(l);
      }
    }

    //create "psuedo-multimap" sorted low to high by the highest y-value
    TreeMap<Float, ArrayList<Line>> highLSort = new TreeMap<Float, ArrayList<Line>>();
    for (Line l : lines)
    {
      if (l.x1 != l.x2) //do not include vertical lines
      {
        Float maxX = max(l.x1, l.x2);
        ArrayList<Line> sameMaxX = highLSort.get(maxX);
        if (sameMaxX == null)
        {
          highLSort.put(maxX, sameMaxX = new ArrayList<Line>());
        }
        sameMaxX.add(l);
      }
    }


    int numScanLines = (int)(buildAreaX / nozzleDiam);
    int numDrawnLines = (int) (numScanLines * infill);
    float interval = numScanLines / numDrawnLines * nozzleDiam;

    float minX = getMinX(layer);
    float maxX = getMaxX(layer);

    for (float currScan = minX; currScan < maxX; currScan += interval)
    {
      NavigableMap<Float, ArrayList<Line>> lowerLines = lowLSort.headMap(currScan, true);
      NavigableMap<Float, ArrayList<Line>> upperLines = highLSort.tailMap(currScan, true);

      //get a HashSet<Line> of the lines that are in both submaps
      HashSet<Line> allLowerLines = extractLines(lowerLines.values());
      HashSet<Line> allUpperLines = extractLines(upperLines.values());
      allLowerLines.retainAll(allUpperLines);
      HashSet<Line> ixLines = allLowerLines;
      int numLines = ixLines.size();


      if (numLines % 2 != 0)
      {
        println("Slicer.addInfill(): Non-closed figure at layer height: "+ layer.zHeight +
          " and xPos: " + currScan);
      } else
      {
        //sort lines by their mininum y value
        ArrayList<Line> sortByMinY = new ArrayList<Line>(ixLines);
        sortByMinY.sort(new LineMinYComparator());

        Float y1 = null;
        for (Line l : sortByMinY)
        {
          //start + (stop-start) * amount
          float liFactor = (currScan - l.x1) / (l.x2 - l.x1);

          if (y1 == null)
          {
            //calculate first point
            y1 = (l.y2 - l.y1) * liFactor + l.y1;
          } else
          {
            //calculate second point
            Float y2 = (l.y2 - l.y1) * liFactor + l.y1;

            //add travel to layer
            layer.addLine(new Line(currScan, y1, currScan, y2, false));

            y1 = null;
          }
        }
      }
    }
    return layer;
  }


  /**
   * This metod will return a PVector with the lowest Z-position.
   *
   * @param  f  The facet to check Z values of the vertices.
   * @return    The PVector (x, y, z) vertex with the lowest Z value from the facet.
   */
  private PVector getLowestZVertex(Facet f)
  {
    PVector[] verts = f.getVerticies();
    PVector lowest = verts[0];
    if (verts[1].z < lowest.z)
    {
      lowest = verts[1];
    }
    if (verts[2].z < lowest.z)
    {
      lowest = verts[2];
    }
    return lowest;
  }


  /**
   * This metod will return a PVector with the highest Z-position.
   *
   * @param  f  The facet to check Z values of the vertices.
   * @return    The PVector (x, y, z) vertex with the highest Z value from the facet.
   */
  private PVector getHighestZVertex(Facet f)
  {
    PVector[] verts = f.getVerticies();
    PVector highest = verts[0];
    if (verts[1].z > highest.z)
    {
      highest = verts[1];
    }
    if (verts[2].z > highest.z)
    {
      highest = verts[2];
    }
    return highest;
  }


  /**
   * This metod will return the smallest Y position of a given layer.
   *
   * @param  l  The layer to check the Y values.
   * @return    The lowest Y value in the layer.
   */
  private Float getMinY(Layer l)
  {
    ArrayList<Line> lines = l.getCoordinates();  
    Float minY = null;
    if (lines != null && lines.size() > 0)
    {
      minY = lines.get(0).y1;
      for (Line li : lines)
      {
        if (li.y1 < minY)
        {
          minY = li.y1;
        }
        if (li.y2 < minY)
        {
          minY = li.y2;
        }
      }
    }

    return minY;
  }


  /**
   * This metod will return the largest Y position of a given layer.
   *
   * @param  l  The layer to check the Y values.
   * @return    The largest Y value in the layer.
   */
  private Float getMaxY(Layer l)
  {
    ArrayList<Line> lines = l.getCoordinates();  
    Float maxY = null;
    if (lines != null && lines.size() > 0)
    {
      maxY = lines.get(0).y1;
      for (Line li : lines)
      {
        if (li.y1 > maxY)
        {
          maxY = li.y1;
        }
        if (li.y2 > maxY)
        {
          maxY = li.y2;
        }
      }
    }

    return maxY;
  }


  /**
   * This metod will return the largest X position of a given layer.
   *
   * @param  l  The layer to check the X values.
   * @return    The largest X value in the layer.
   */
  private Float getMaxX(Layer l)
  {
    ArrayList<Line> lines = l.getCoordinates();  
    Float maxX = null;
    if (lines != null && lines.size() > 0)
    {
      maxX = lines.get(0).x1;
      for (Line li : lines)
      {
        if (li.x1 > maxX)
        {
          maxX = li.x1;
        }
        if (li.x2 > maxX)
        {
          maxX = li.x2;
        }
      }
    }

    return maxX;
  }


  /**
   * This metod will return the smallest X position of a given layer.
   *
   * @param  l  The layer to check the X values.
   * @return    The smallest X value in the layer.
   */
  private Float getMinX(Layer l)
  {
    ArrayList<Line> lines = l.getCoordinates();  
    Float minX = null;
    if (lines != null && lines.size() > 0)
    {
      minX = lines.get(0).x1;
      for (Line li : lines)
      {
        if (li.x1 < minX)
        {
          minX = li.x1;
        }
        if (li.x2 < minX)
        {
          minX = li.x2;
        }
      }
    }

    return minX;
  }


  /**
   * This method will return all of the facets located within a Collection of ArrayList<Facet>s.
   *
   * @param  col  The collection of ArrayList<Facet>s.
   * @return A HashSet containing all the facets from col.
   */
  private HashSet<Facet> extractFacets(Collection<ArrayList<Facet>> col)
  {
    HashSet<Facet> allFacets = new HashSet<Facet>();

    for (ArrayList<Facet> af : col)
    {
      allFacets.addAll(af);
    }

    return allFacets;
  }


  /**
   * This method will return all of the lines located within a Collection of ArrayList<Line>s.
   *
   * @param  col  The collection of ArrayList<Line>s.
   * @return A HashSet containing all the lines from col.
   */
  private HashSet<Line> extractLines(Collection<ArrayList<Line>> col)
  {
    HashSet<Line> allLines = new HashSet<Line>();

    for (ArrayList<Line> al : col)
    {
      allLines.addAll(al);
    }

    return allLines;
  }


  /* returns the number of vertecies in f that are above a given Z-height*/
  /**
   * This method will return the number of vertices in the inpiut facet that are above
   * an input Z height.
   *
   * @param  f      The Facet object to get the vertices from.
   * @param  zPos   The Z value to check against.
   * @return        The number of vertices that are above zPos in the Facet f.
   */
  private int numVerteciesAbove(Facet f, float zPos)
  {
    int count = 0;
    PVector[] verts = f.getVerticies();
    for (PVector v : verts)
    {
      if (v.z > zPos)
      {
        count++;
      }
    }
    return count;
  }

  /**
   *  Determines the actual travels needed to print a sliced layer object
   *  in the order of lines in the array list, a line is added from the endpoint of the previous line (line 0 uses origin of (0,0) )
   *  to the startpoint of the next line in the array list.
   *
   *  @param    layer  the layer for which the tool path is to be extracted
   *  @param    xInit  initial x position of the extruder
   *  @param    yInit  initial y position of the extruder
   *  @returns  an ArrayList of all print lines and travel lines
   */
  private ArrayList getToolPath(Layer l)
  {
    ArrayList<Line> layerLines = l.getCoordinates(); //get all the lines in the layer
    ArrayList<Line> toolPath = new ArrayList(); //array list of lines to represent extruder movements
    toolPath.add(0, new Line(xInit, yInit, xInit, yInit, true)); //adds a travel move from initial position to inital position, this will be removed at the end of the algorithm

    while (layerLines.size() != 0) //loops until every Line has been found
    {
      Line currLine = toolPath.get(toolPath.size()-1); // Line from which the extruder will be moving from
      Line checkLine = layerLines.get(0); //Line whose distance is being checked  
      Line closeLine = checkLine; //Line which is the closest to currLine
      float minDist = currLine.getDist(checkLine); //distance between currLine and checkLine
      for (int i = 0; i<layerLines.size()-1; i++) 
      {
        checkLine = layerLines.get(i);
        if (currLine.getDist(checkLine) < minDist)
        {
          closeLine = checkLine;
          minDist = currLine.getDist(closeLine);
        }
      }
      if (minDist > nozzleDiam - .002) //if the distance is greater than nozzle diameter then a travel from currLine to closeLine is needed. 
      {
        toolPath.add(toolPath.size(), new Line(toolPath.get(toolPath.size()-1).x2, toolPath.get(toolPath.size()-1).y2, closeLine.x1, closeLine.y1, true));
      }
      toolPath.add(toolPath.size(), closeLine);
      layerLines.remove(closeLine);
    }
    toolPath.remove(0); //removes the psudeo travel move at position 0
    xInit = toolPath.get((toolPath.size()-1)).x2;
    yInit = toolPath.get((toolPath.size()-1)).y2;
    return toolPath;
  }
}


/* Implements a java.util.Comparator to compare the Z-height of two PVectors */
private class PVectorZComparator implements Comparator<PVector>
{
  @Override
    public int compare(PVector a, PVector b)
  {
    return a.z == b.z ? 0 : a.z < b.z ? -1 : 1;
  }
}

/* Implements a java.util.Comparator to compare the x1 of two Lines */
private class lineXComparator implements Comparator<Line>
{
  @Override
    public int compare(Line a, Line b)
  {
    return a.x1 == b.x1 ? 0 : a.x1 < b.x1 ? -1 : 1;
  }
}

/* Implements a java.util.Comparator to compare the y1 of two Lines */
private class lineYComparator implements Comparator<Line>
{
  @Override
    public int compare(Line a, Line b)
  {
    return a.y1 == b.y1 ? 0 : a.y1 < b.y1 ? -1 : 1;
  }
}

/* Implement a java.util.Comparater to compare the smallest x value of two Lines */
private class LineMinXComparator implements Comparator<Line>
{
  @Override
    public int compare(Line a, Line b)
  {
    float aMinX = min(a.x1, a.x2);
    float bMinX = min(b.x1, b.x2);
    return aMinX == bMinX ? 0 : aMinX < bMinX ? -1 : 1;
  }
}

/* Implement a java.util.Comparater to compare the smallest y value of two Lines */
private class LineMinYComparator implements Comparator<Line>
{
  @Override
    public int compare(Line a, Line b)
  {
    float aMinY = min(a.y1, a.y2);
    float bMinY = min(b.y1, b.y2);
    return aMinY == bMinY ? 0 : aMinY < bMinY ? -1 : 1;
  }
}