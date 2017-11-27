/*
Line.pde
 
 This Sketchbook tab holds the definition and implementation of the Line class.
 
 The Line class represents a movement of the print head of a 3D printer. The movements
 can either be a travel movement or a extrusion movement. These movements are
 represented as a 2D line segment made up of two points. Both points are publicly
 accessible.
 
 Authors: Slicing Team (Andrew Figueroa)
 */


public class Line {
  
  public float x1;
  public float y1;
  public float x2;
  public float y2;
  public boolean isTravel;


  /**
   * Constructor for a line object given 2 points and a boolean.
   *
   * @param  x1        The x value of the start point.
   * @param  y1        The y value of the start point.
   * @param  x2        The x value of the end point.
   * @param  y2        The y value of the end point.
   * @param  isTravel  Denotes whether the current line is a toolpath travel line.
   */
  public Line(float x1, float y1, float x2, float y2, boolean isTravel) {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    this.isTravel = isTravel;
  }


  /*
  * This method will return the distance between the current line, and a given point (xIn, yIn).
   *
   * @param  xIn  The x coordinate of the target point
   * @param  yIn  The y coordinate of the target point
   * @return      The distance between this line and a given point.
   */
  public float getDist(float xIn, float yIn)
  {
    return (float) Math.sqrt((x2-xIn)*(x2-xIn)+(y2-yIn)*(y2-yIn));
  }

  /**
   * This method will swap the start point and the end point of this line.
   */
  public void swapPoints()
  {
    float temp = x2;
    x2 = x1;
    x1 = temp;
    temp = y2;
    y2 = y1;
    y1 = temp;
  }
}