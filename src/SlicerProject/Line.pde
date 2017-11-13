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
  
  public Line(float x1, float y1, float x2, float y2, boolean isTravel) {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    this.isTravel = isTravel;
  }
}