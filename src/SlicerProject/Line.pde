/*
Line.pde
 
 This Sketchbook tab holds the definition and implementation of the Line class.
 
 The Line class represents a movement of the print head of a 3D printer. The movements
 can either be a travel movement or a extrusion movement. These movements are
 represented as a 2D line segment made up of two points. Both points are publicly
 accessible.
 
Authors: Slicing Team (Andrew Figueroa, Aaron Finnegan, Chris Iossa)

*/

public class Line {
  
  public float x1;
  public float y1;
  public float x2;
  public float y2;
  public boolean isTravel;
  public boolean isInfill;


  /**
   * Constructor for a line object given 2 points and a boolean.
   *
   * @param  x1        The x value of the start point.
   * @param  y1        The y value of the start point.
   * @param  x2        The x value of the end point.
   * @param  y2        The y value of the end point.
   * @param  isTravel  Denotes whether the current line is a toolpath travel line.
   */
  public Line(float x1, float y1, float x2, float y2, boolean isTravel, boolean isInfill) {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    this.isTravel = isTravel;
    this.isInfill = isInfill;
  }
  
  public float getX1(){
    return x1;
  
  }
  
   public float getX2(){
    return x2;
  
  }
  
  public float getY1(){
    return y1;
  
  }
  public float getY2(){
    return y2;
  
  }
  public boolean getTravel(){
    return isTravel;
  }
  
  public void setX1(float x1){
  this.x1 = x1;
  }
  
  public void setX2(float x2){
  this.x2 = x2;
  }
  
   public void setY1(float y1){
  this.y1 = y1;
  }
  
  public void setY2(float y2){
  this.y2 = y2;
  }
  
  public void setTravel(Boolean isTravel){
    this.isTravel= isTravel;
  }
  

  /*
  * returns the distance between this line and another Line @param lineIn 
  * @param  lineIn  the Line to compare the current Line object with
  */
  public float getDist(Line lineIn)
  {
    float unFlippedDist=(float) Math.sqrt((x2-lineIn.x1)*(x2-lineIn.x1)+(y2-lineIn.y1)*(y2-lineIn.y1));
    lineIn.swapPoints();
    
    float flippedDist=(float) Math.sqrt((x2-lineIn.x1)*(x2-lineIn.x1)+(y2-lineIn.y1)*(y2-lineIn.y1));
    
    if(unFlippedDist<flippedDist)
    {
      lineIn.swapPoints();
      return unFlippedDist;
    }
    else
    {
     return flippedDist; 
    }
    
  }

  /**
   * This method will swap the x1/y1 and x2/y2 points of the line.
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