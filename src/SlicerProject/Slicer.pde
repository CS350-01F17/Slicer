/*
Slicer.pde

This Sketchbook tab holds the definition and implementation of the Slicer class.

The Slicer class represents the controller for the slicing process that converts a 3D
 model into a series of 2D layers. Methods are provided to turn Facets that make up a
 3D model into a list of layers, and to process the layers into RepRap GCode that provides
 instructions to a 3D printer on how to physically reproduce the 3D model.
 
TODO: Currently, only the most basic slicing has been implemented. Walls, top and bottom
 layers, travels, and GCode creation have not yet been implemented.

Authors:
 Andrew Figueroa, Aaron Finnegan (Slicing Team)
*/

import java.util.Arrays;
import java.util.Collection;
import java.util.NavigableMap;
import java.util.TreeMap;
import java.util.Comparator;
import java.util.HashSet;

public class Slicer
{
  private TreeMap<Float, ArrayList<Facet>> lowVSort;
  private TreeMap<Float, ArrayList<Facet>> highVSort;
  private final float layerHeight;
  private final float infillPercentage;
 
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
    }
    else if (infill < 0.0)
    {
      infill = 0;
    }
    this.infillPercentage = infill; //TODO: validate
    
    //create "psuedo-multimap" sorted low to high by the lowest z-height
    lowVSort = new TreeMap<Float, ArrayList<Facet>>();
    for (Facet f: facets)
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
    for (Facet f: facets)
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
    
    ArrayList<Layer> layers = new ArrayList<Layer>();
    layers.ensureCapacity((int)(highestPos / layerHeight) + 1);
    
    for (float pos = 0; pos < highestPos; pos += layerHeight)
    {
      //TODO: account for bottom and top layers (these need an infill of 1)
      
      Layer currLayer = sliceLayer(pos);
      //currLayer = addInfill(currLayer, infillPercentage);
      //TODO: add walls
      //TODO: compute travels
      
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
  * @return  An ArrayList<String> of RepRap GCode commands ready to be sent to a printer
  */
  public ArrayList<String> createGCode(ArrayList<Layer> layers)
  {
    ArrayList<String> gCode = null;
    //TODO: Implement createGCode()
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
    
    //TEMP: Debug info
    println("Slicer.sliceLayer(): Intersecting facets at height " + zPos + ": " +
            intersectingFacets.size());
    
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
      }
      else if (numHigherVerts == 1) //1 point above, 2 points below or on current plane 
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
      }
      else //2 points above, 1 point below or on current plane
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
  * @return  An ArrayList<String> of GCode commands that will print the given layer
  */
  private ArrayList<String> layerToGCode(Layer l)
  {
    ArrayList<String> LayerGCode = null;
    //TODO: implement layerToGCode()
    return LayerGCode;
  }
  
  
  /**
  * Adds structural infill to the given layer
  *
  * This method adds Line objects to the given Layer that represent infill. The
  * the given layer must represent a closed figure. An infill percentage of 1 will
  * result in a layer with no hollow portion (useful for bottom and top layers)
  *
  * @param  layer  The Layer object to add infill to
  * @param  infillPercentage  Amount of infill to add to the layer (0 to 1)
  * @return The layer object with infill added
  */
  private Layer addInfill(Layer l)
  {
    Layer layerInfill = null;
    //TODO: implement addInfill()
    return layerInfill;
  }
  
  
  /* returns a PVector of the vertex with the lowest z-position */
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
  
  
  /* returns a PVector of the vertex with the highest z-position */
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
  
  
  /* returns all of the facets located within a Collection of ArrayLists<Facet>s */
  private HashSet<Facet> extractFacets(Collection<ArrayList<Facet>> col)
  {
    HashSet<Facet> allFacets = new HashSet<Facet>();
    
    for (ArrayList<Facet> af : col)
    {
      allFacets.addAll(af);
    }
    
    return allFacets;
  }
  
  
  /* returns the number of vertecies in f that are above a given Z-height*/
  private int numVerteciesAbove(Facet f, float zPos)
  {
    int count = 0;
    PVector[] verts = f.getVerticies();
    for (PVector v: verts)
    {
      if (v.z > zPos)
      {
        count++;
      }
    }
    return count;
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