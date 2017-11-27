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
  private ArrayList<Line> lines; 


  /**
   * Constructor for Layer object given an initial z value.
   *
   * @param  inputZHeight  The Z height value to assign to this layer.
   */
  public Layer(float inputZHeight)
  {
    zHeight = inputZHeight;
    lines = new ArrayList<Line>();
  }


  /**
   * Constructor for Layer object given an ArrayList<Line> and initial z value.
   *
   * @param  importLines   The list of lines to assign to this layer.
   * @param  inputZHeight  The Z height value to assign to this layer.
   */
  public Layer(ArrayList<Line> importLines, float inputZHeight)
  {
    lines = new ArrayList<Line>(importLines);
    zHeight = inputZHeight;
  }


  /**
   * Constructor for default Layer object with no lines in the ArrayList<Line>, and no z value (0).
   */
  public Layer()
  {
    zHeight = 0;
  }


  /**
   * This method returns the list of lines that are present in the current layer. 
   * 
   * @return  an ArrayList<Line> of lines within this layer.
   */
  public ArrayList<Line> getCoordinates() 
  {
    return lines;
  }

  /**
   * This method will clear the current contents of the ArrayList<> lines and add all elements
   * of the ArrayList<> newLineList to the current ArrayList<> lines.
   *
   * @param   ArrayList<Line>  The new ArrayList<> of Lines to insert to this layer.  
   */
  public void setCoordinates(ArrayList<Line> newLineList)
  {
    // Clear the current lines list in this object.
    lines.clear();
    
    // Add each element from the newLineList to lines.
    for (Line newLine : newLineList)
    {
     lines.add(newLine); 
    }
  }
  
  /**
   * This method adds a new line to the instance variable holding the ArrayList of Line objects
   * 
   * @param  newLine  the Line to add to the ArrayList<Line> of Line objects
   */
  public void addLine(Line newLine)
  {
    lines.add(newLine);
  }
}