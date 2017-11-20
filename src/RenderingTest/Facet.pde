/*
Facet.pde
 
 This Sketchbook tab holds the definition and implementation of the Facet class.
 
 The Facet class represents a trangulated surface defined by a unit normal and 3
 verticies ordered by the right-hand-rule that use a 3D cartesian coordinate system. 
 Essentially, it is a triangle located in 3D space. Multiple facets can be composed
 together to represent a 3D model.
 
 Authors:
 Slicing Team
 Chris Iossa (https://www.github.com/ChrisIossa)
 Paul Canada
 */

class Facet {

  private PVector vertex1, vertex2, vertex3, facetNormal;

  //constructor that initalizes the vertices
  public Facet(PVector vertex1, PVector vertex2, PVector vertex3)
  {
    this.vertex1 = vertex1;
    this.vertex2 = vertex2;
    this.vertex3 = vertex3;
    facetNormal = null;
  }
  
  //constructor that initalizes the vertices and facet normal
  public Facet(PVector vertex1, PVector vertex2, PVector vertex3, PVector facetNormal)
  {
    this.vertex1 = vertex1;
    this.vertex2 = vertex2;
    this.vertex3 = vertex3;
    this.facetNormal = facetNormal;
  }

  public Facet()
  {
    vertex1 = null;
    vertex2 = null;
    vertex3 = null;
    facetNormal=null;
  }

  /*
    This method will handle setting the verticies of the facet.
   @param    verticiesInput
   */
  public boolean setVertex(int vertexIndex, PVector vertexInput)
  {
    if (vertexInput == null)
    {
      println("Input verticies cannot be null.");
      return false;
    }

    try {
      switch(vertexIndex)
      {
      case 0:
        vertex1 = vertexInput;
        break;

      case 1:
        vertex2 = vertexInput;
        break;

      case 2:
        vertex3 = vertexInput;
        break;

      default:
        println("Invalid index for vertex.");
        return false;
      }

      return true;
    }
    catch (NullPointerException e)
    {
      println("Input vertex cannot be null.");

      return false;
    }
  }
  
  //function to set facet normal to value specefied @param facetNormal
  
  public boolean setFacetNormal(PVector facetNormal)
  {
    try 
    {
      this.facetNormal = facetNormal;
      return true;
    }
    catch (NullPointerException e)
    {
      println("Cannot set a null PVector to a facetNormal.");

      return false;
    }
  }
  
  //function takes 3 PVectors, and sets them to the facet's corresponding PVector variables
  public boolean setVertices(PVector vertex1, PVector vertex2, PVector vertex3)
  {
    try 
    {
      this.vertex1 = vertex1;
      this.vertex2 = vertex2;
      this.vertex3 = vertex3;

      return true;
    }
    catch (NullPointerException e)
    {
      println("Cannot set a null vertex to facet.");

      return false;
    }
  }
  
  public PVector GetLowest()
    {
      if(vertex1.z < vertex2.z)
        {
          if(vertex3.z < vertex1.z)
            {
              return vertex3;
            }
          else
            {
              return vertex1;
            }
        }
      else if(vertex2.z < vertex3.z)
        {
          return vertex2;
        }
      else
        {
          return vertex3;
        }
    }

  //getter for facetNormal
  
  public PVector getFacetNormal()
  {
    return facetNormal;
  }
  
  //getter for vertexes
  public PVector[]  getVerticies()
  {
    return new PVector[] { vertex1, vertex2, vertex3 };
  }
}