/*
Layer.pde
 
 This Sketchbook tab holds the definition and implementation of the Layer class.
 
 The Layer class represents the layers of a sliced 3D model. These layers represent
 locations where the print head will move over, either while extruding material or
 travelling to another location. These locations are represented as line segments
 of type Line.
 
 Wall implementation was planned, but we did not have enough time to iron out
 the issues that came up with wall implementation.
 As such, the methods for wall creation are left in the file, but are commented out.
 @see Layer.calcYOffset()
 @see Layer.calcXOffset()
 @see Layer.createWalls()
 
 Authors: Slicing Team (Paul Canada) (Aaron Finnegan)
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

/**
 * Start of non-working implementation for wall creation.
 */

  /*
  
   this method will take a layer and then
   return an array list of lines that will act as the walls that provide stuctural support.
   it will do this by seaching each layer for each set of connected lines 
   
   
   this function is:
   currently non-functional
   able to do sorting and can currently sort closed shapes(not verified via extensive testing)
   it does not properly create lines that will act as walls 
   it can find the shared points of 2 lines that are connected
   it does find the propper offset of the point it needs 
   
   */


  /*
  public ArrayList<Line> createWalls(int numWalls, float nozzelSize  )
  {


    ArrayList<Line> allWalls = new ArrayList<Line>();//all the lines that make up the walls
    ArrayList<Line> unconnectedWalls = new ArrayList<Line>();//this list holds all 


    allWalls.add(lines.get(0));
    int prevWallStartIndex=0;


    //Sort the array list that is coming in 

    for (int i =1; i<lines.size(); i++)
    {
      //find the shared point 
      Line testLine = lines.get(i);
      //shared point is the first point in the test line and the first point in the previous line
      if (testLine.getX1() == allWalls.get(allWalls.size()-1).getX1()  &&  testLine.getY1() == allWalls.get(allWalls.size()-1).getY1())
      {
        allWalls.add(testLine);
      }
      //shared point is the first point in the test line and the second point in the previous line 
      else if ( testLine.getX1() == allWalls.get(allWalls.size()-1).getX2()  &&  testLine.getY1() == allWalls.get(allWalls.size()-1).getY2())
      {
        allWalls.add(testLine);
      }
      //shared point is the first point in the test line and the second point in the previous line 
      else if ( testLine.getX2() == allWalls.get(allWalls.size()-1).getX1()  &&  testLine.getY1() == allWalls.get(allWalls.size()-1).getY1())
      {
        allWalls.add(testLine);
      }
      //shared point is the first point in the test line and the second point in the previous line 
      else if ( testLine.getX2() == allWalls.get(allWalls.size()-1).getX2()  &&  testLine.getY2() == allWalls.get(allWalls.size()-1).getY2())
      {
        allWalls.add(testLine);
      }
       else//there is no shared point in the previous and the test line
      {

        if (unconnectedWalls.size()!=0)
        {
          for (int j =0; j<unconnectedWalls.size(); j++)//check past lines to find a possible connected one 
          {

            if (unconnectedWalls.get(j).getX1() == testLine.getX1()  &&  unconnectedWalls.get(j).getY1() == testLine.getY1())
            {
              allWalls.add(unconnectedWalls.get(j));
              unconnectedWalls.remove(j);
            }
            //shared point is the first point in a previously unconnected line and the second point in the previous line 
            else if ( unconnectedWalls.get(j).getX1() == testLine.getX2()  &&  unconnectedWalls.get(j).getY1() == testLine.getY2())
            {
              allWalls.add(unconnectedWalls.get(j));
              unconnectedWalls.remove(j);
            }
            //shared point is the first point in a previously unconnected line and the second point in the previous line 
            else if ( unconnectedWalls.get(j).getX2() == testLine.getX1()  &&  unconnectedWalls.get(j).getY1() == testLine.getY1())
            {
              allWalls.add(unconnectedWalls.get(j));
              unconnectedWalls.remove(j);
            }
            //shared point is the first point in a previously unconnected line and the second point in the previous line 
            else if ( unconnectedWalls.get(j).getX2() == testLine.getX2()  &&  unconnectedWalls.get(j).getY2() == testLine.getY2())
            {
              allWalls.add(unconnectedWalls.get(j));
              unconnectedWalls.remove(j);
            } else
            {
              unconnectedWalls.add(testLine);
              println("unconnected wall had no shared point");
            }
          }
        } else
        {
          unconnectedWalls.add(testLine);
        }
        // allWalls.add(allWalls.get(prevWallStartIndex));
        // allWalls.add(allWalls.get(i));

        prevWallStartIndex = i;
      }
    }
    boolean allLinesChecked = false;
    while (unconnectedWalls.size()>0 && !allLinesChecked)
    {
      Line testLine = allWalls.get(allWalls.size()-1);
      for (int j =0; j<unconnectedWalls.size(); j++)//check past lines to find a possible connected one 
      {

        if (unconnectedWalls.get(j).getX1() == testLine.getX1()  &&  unconnectedWalls.get(j).getY1() == testLine.getY1())
        {
          allWalls.add(unconnectedWalls.get(j));
          unconnectedWalls.remove(j);
        }
        //shared point is the first point in a previously unconnected line and the second point in the previous line 
        else if ( unconnectedWalls.get(j).getX1() == testLine.getX2()  &&  unconnectedWalls.get(j).getY1() == testLine.getY2())
        {
          allWalls.add(unconnectedWalls.get(j));
          unconnectedWalls.remove(j);
        }
        //shared point is the first point in a previously unconnected line and the second point in the previous line 
        else if ( unconnectedWalls.get(j).getX2() == testLine.getX1()  &&  unconnectedWalls.get(j).getY1() == testLine.getY1())
        {
          allWalls.add(unconnectedWalls.get(j));
          unconnectedWalls.remove(j);
        }
        //shared point is the first point in a previously unconnected line and the second point in the previous line 
        else if ( unconnectedWalls.get(j).getX2() == testLine.getX2()  &&  unconnectedWalls.get(j).getY2() == testLine.getY2())
        {
          allWalls.add(unconnectedWalls.get(j));
          unconnectedWalls.remove(j);
        }
      }
      allLinesChecked = true;
    }


    for (int j =0; j< allWalls.size(); j++)
    {
      println( "allWalls[" + j+"]: (" +allWalls.get(j).getX1()+ ","+allWalls.get(j).getY1()+") ("+allWalls.get(j).getX2()+ ","+allWalls.get(j).getY2()+")"  );
    }
    println("");

    ///////END OF SORTING********************************* 


    ArrayList<Line> walls= new ArrayList<Line>();//array to be returned after being offset from 


    int numOfPrevLines =0;// the number of lines made per each itteration

    float prevX=0;
    float prevY=0;


    givenLines.add(givenLines.get(0));

    for (int i =0; i<givenLines.size()-1; i++)
    { 

      //declare variables for the use in creation of walls
      float offset;//the hypotenuse of the triangle in formulas
      float sharedAngle; //the theta angle of the triangle in formulas
      //create 3 PVectors to make the points of the angle
      PVector point1 = new PVector ();
      PVector point2 = new PVector();
      PVector sharedPoint = new PVector();

      //get the pointsfor line 1
      float line1X1= givenLines.get(i+1).getX1();
      float line1Y1= givenLines.get(i+1).getY1();

      float line1X2= givenLines.get(i+1).getX2();
      float line1Y2= givenLines.get(i+1).getY2();
      //get the points for line 2
      float line2X1= givenLines.get(i).getX1();
      float line2Y1= givenLines.get(i).getY1();

      float line2X2= givenLines.get(i).getX2();
      float line2Y2= givenLines.get(i).getY2();
      //the shared point is the first point of both lines
      if (line1X1== line2X1 && line1Y1== line2Y1)
      {
        sharedPoint.set(line1X1, line1Y1);//set the point that is shared
        point1     .set(line2X2, line2Y2);//set point1
        point2     .set(line1X2, line1Y2);//set point2
      }
      //the shared point is the line1 point 1 and line 2 point 2
      else if (line1X1== line2X2 && line1Y1== line2Y2)
      {
        sharedPoint .set(line1X1, line1Y1);//set the shared point 
        point1      .set(line2X1, line2Y1);//set point1
        point2      .set(line1X2, line1Y2);//set point2
      }
      // the shared point is line 1 point and line 2 point 1
      else if (line1X2== line2X1 && line1Y2== line2Y1)
      {
        sharedPoint .set(line1X2, line1Y2);//set the shared point
        point1      .set(line2X2, line2Y2);//set point1
        point2      .set(line1X1, line1Y1);//set point2
      }
      // the shared point is line 1 point 2 and line 2 point 2
      else
      { 
        sharedPoint .set(line1X2, line1Y2);//set the shared point
        point1      .set(line2X1, line2Y1);//set point1
        point2      .set(line1X1, line1Y1);//set point2
      }
      sharedAngle = PVector.angleBetween(point1, point2);//calculate the angle between the points
      sharedAngle = sharedAngle/2;//get the theta angle for the angle between points

      //calculation of the offset
      offset = (sin(radians(1.5708))*(nozzelSize/(sin(radians(abs(sharedAngle))))));


      // testing & debugging output line
      println("offset= " + offset + " sharedAngle =" + sharedAngle+ " sharedpoint (" + sharedPoint.x + "," + sharedPoint.y + ")");//test line
      print(" sharedpoint (" + point1.x + "," + point1.y + ")");//test line
      print(" sharedpoint (" + point2.x + "," + point2.y + ")");//test line

      //0 if first itteration of the loop
      if (i ==0)
      {
        prevX = calcOffsetX(sharedPoint, offset);//offset the x for the new point
        prevY = calcOffsetY(sharedPoint, offset);//offset the y for the new point
      }
      //the last itteration
      else if (i == givenLines.size()-2)
      { 
        float curX = calcOffsetX(sharedPoint, offset);//offset the x for the new point
        float curY = calcOffsetY(sharedPoint, offset);//offset the y for the new point

        PVector testPoint2 = new PVector(curX, curY);
        PVector testPoint1 = new PVector(prevX, prevY); 

        if (PVector.dist(testPoint1, testPoint2) < nozzelSize)// the line is smaller than the actual size it is being offset
        {

          println( "distance between 2 points is: " + PVector.dist(testPoint1, testPoint2));//test line
        }
         else// the line is large enough for printing 
        {
          walls.add(new Line(prevX, prevY, curX, curY, false));//create a line with the previous points and current points to add 
          println( "Walls[" + (walls.size()-1)+"]: (" +walls.get(walls.size()-1).getX1()+ ","+walls.get(walls.size()-1).getY1()+") ("+walls.get(walls.size()-1).getX2()+ ","+walls.get(i).getY2()+")"  );//test line
        }
        prevX = curX;//set the previous x to the current x
        prevY = curY;//set the previous x to the current Y
        testPoint1 = new PVector(prevX, prevY); 


        if (PVector.dist(testPoint1, testPoint2) < nozzelSize)// the line is smaller than the actual size it is being offset
        {
          print( "distance between 2 points is: " + PVector.dist(testPoint1, testPoint2));//test line
          println("(" + testPoint1.x+"," + testPoint1.y+") ("+testPoint2.x+","+testPoint2.y+")" );//test line
        } else
        {
          //create a line between the first point made and the last point made
          walls.add(new Line(prevX, prevY, walls.get(0).getX1(), walls.get(0).getY1(), false));
          println( "Walls[" +(walls.size()-1) +"]: (" +walls.get(walls.size()-1).getX1()+ ","+walls.get(walls.size()-1).getY1()+") ("+walls.get(walls.size()-1).getX2()+ ","+walls.get(i).getY2()+")"  );//test line
        }

        numOfPrevLines = givenLines.size()-1;
        // println(numOfPrevLines); //test Line
      }
      //every other itteration
      else
      {
        float curX = calcOffsetX(sharedPoint, offset);//offset the x for the new point
        float curY = calcOffsetY(sharedPoint, offset);//offset the y for the new point

        PVector testPoint1 = new PVector(prevX, prevY); 
        PVector testPoint2 = new PVector(curX, curY);
        if (PVector.dist(testPoint1, testPoint2) < nozzelSize)// the line is smaller than the actual size it is being offset
        {
          print( "distance between 2 points is: " + PVector.dist(testPoint1, testPoint2));
          println(": (" + testPoint1.x+"," + testPoint1.y+") ("+testPoint2.x+","+testPoint2.y+")" );
        } else
        {
          walls.add(new Line(prevX, prevY, curX, curY, false));//create a line with the previous points and current points to add
        }
        prevX = curX;//set the previous x to the current x
        prevY = curY;//set the previous x to the current Y
      }
    }
  }

  return walls;
}
*/



  /**
   * This method will offset the X value of the point and then return the updated value.
   *
   * @param point  The point object to get the X value from.
   * @param offset The offset to add 
   */
   /*
  private float calcOffsetX(PVector point, float offset)
  {      
    if ((point.x >= (0 - offset)) && (point.x < (0 + offset)))
    {
      return point.x;
    } else if (point.x <0 )
    {
      return point.x + offset;
    } else
    {
      return point.x - offset;
    }
  }
  */





  /**
   * This method will offset the Y value of the point and then return the updated value.
   *
   * @param point  The point object to get the Y value from.
   * @param offset The offset to add 
   */
   /*
  private float calcOffsetY(PVector point, float offset)
  { 
    if ((point.y >= (0 - offset)) && (point.y < (0 + offset)))
    {
      return point.y;
    } else if (point.y <0 )
    {
      return point.y + offset;
    } else
    {
      return point.y - offset;
    }
  }
  */