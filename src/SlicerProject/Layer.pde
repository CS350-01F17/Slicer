/*
Layer.pde

This Sketchbook tab holds the definition and implementation of the Layer class.

The Layer class represents the layers of a sliced 3D model. These layers represent
 locations where the print head will move over, either while extruding material or
 travelling to another location. These locations are represented as line segments
 of type Line.
 
Authors: Slicing Team (Paul Canada)
*/

public class Layer
{
  
  private float zHeight;
  private ArrayList<Line> lines = new ArrayList<Line>(); 


  /*
    Constructor for Layer object given an initial z value.
  */
  public Layer(float inputZHeight)
  {
    zHeight = inputZHeight;
  }
  
  
  /*
    Constructor for Layer object given an ArrayList<Line> and initial z value.
  */
  public Layer(ArrayList<Line> importLines, float inputZHeight)
  {
    setCoordinates(importLines);
    zHeight = inputZHeight;
  }
  
  
  /*
    Constructor for default Layer object with no lines in the ArrayList<Line>, and no z value (0).
  */
  public Layer()
  {
   zHeight = 0; 
  }
  
  
  /*
    This method returns the lines stored in the layer.
    @return  The ArrayList<Line> of lines in the layer.
  */
  public ArrayList<Line> getCoordinates() 
  {
    return lines;
  }
  
  
  /*
    This method will clear out the current lines ArrayList<Line> and add in a new line object for each line object in newLineList
    @param  newLineList The ArrayList<Line> to import from
  */
  public void setCoordinates(ArrayList<Line> newLineList)
  {
    // Clear out old line segments to put in new line segments.
    lines.clear();
    
    // Add in each line segment to the ArrayList<Line>.
    for (Line newLine : newLineList)
    {
     lines.add(new Line(newLine.x1, newLine.y1, newLine.x2, newLine.y2, newLine.isTravel)); // Need the Line class to check this
    }
    
  }
  
}