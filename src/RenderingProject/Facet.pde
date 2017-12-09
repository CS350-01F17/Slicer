/*
Facet.pde
 
 This Sketchbook tab holds the definition and implementation of the Facet class.
 
 The Facet class represents a trangulated surface defined by a unit normal and 3
 verticies ordered by the right-hand-rule that use a 3D cartesian coordinate system. 
 Essentially, it is a triangle located in 3D space. Multiple facets can be composed
 together to represent a 3D model.
 
 Authors:
 Slicing Team: Chris Iossa (https://www.github.com/ChrisIossa), Paul Canada
 */

class Facet {

  private PVector vertex1, vertex2, vertex3, facetNormal;

  /**
   * Constructor that initializes verticies without a normal.
   *
   * @param  vertex1  The first vertex of the facet.
   * @param  vertex2  The second vertex of the facet.
   * @param  vertex3  The third vertex of the facet.
   */
  public Facet(PVector vertex1, PVector vertex2, PVector vertex3)
  {
    this.vertex1 = vertex1;
    this.vertex2 = vertex2;
    this.vertex3 = vertex3;
    facetNormal = null;
  }


  /**
   * Constructor that initializes verticies with a normal.
   *
   * @param  vertex1  The first vertex of the facet.
   * @param  vertex2  The second vertex of the facet.
   * @param  vertex3  The third vertex of the facet.
   * @param  normal   The normal value of the facet.
   */
  public Facet(PVector vertex1, PVector vertex2, PVector vertex3, PVector facetNormal)
  {
    this.vertex1 = vertex1;
    this.vertex2 = vertex2;
    this.vertex3 = vertex3;
    this.facetNormal = facetNormal;
  }


  /**
   * Default constructor for Facet object without any initialization.
   */
  public Facet()
  {
    vertex1 = null;
    vertex2 = null;
    vertex3 = null;
    facetNormal=null;
  }


  /**
   * This method will handle setting a single vertex of the facet.
   *
   * @param  vertexIndex  Which vertex to modify in this object.
   * @param  vertexInput  The vertex value to insert to this object's vertex.
   * @return The status of the completed operation.
   */
  public boolean setVertex(int vertexIndex, PVector vertexInput)
  {
    if (vertexInput == null)
    {
      println("Input verticies cannot be null.");
      return false;
    }

    // Attempt to assign this object's vertex value to the input value.
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
    // Return false if the input vertex is null.
    catch (NullPointerException e)
    {
      println("Input vertex cannot be null.");

      return false;
    }
  }


  /**
   * This method will handle setting the normal PVector of the facet.
   *
   * @param  facetNormal  The PValue to set the normal to.
   * @return The status of the completed operation.
   */
  public boolean setFacetNormal(PVector facetNormal)
  {
    // Attempt to set the facetNormal of this object to the input facetNormal
    try 
    {
      this.facetNormal = facetNormal;
      return true;
    }
    // Return false if the given normal is null.
    catch (NullPointerException e)
    {
      println("Cannot set a null PVector to a facetNormal.");
      return false;
    }
  }


  /**
   * This method will set this object's 3 verticies to the input verticies.
   *
   * @param  vertex1  The first vertex of the facet.
   * @param  vertex2  The second vertex of the facet.
   * @param  vertex3  The third vertex of the facet.
   * @return The status of the completed operation.
   */
  public boolean setVertices(PVector vertex1, PVector vertex2, PVector vertex3)
  {
    // Attempt to set the verticies of this object to the input vertices.
    try 
    {
      this.vertex1 = vertex1;
      this.vertex2 = vertex2;
      this.vertex3 = vertex3;

      return true;
    }
    // Return false if an input vertex is null.
    catch (NullPointerException e)
    {
      println("Cannot set a null vertex to facet.");

      return false;
    }
  }
  
  public float getLowest()
    {
      if(vertex1.z < vertex2.z)
         {
           if(vertex3.z < vertex1.z)
             {
               return vertex3.z;
             }
           else
             {
               return vertex1.z;
             }
         }
       else if(vertex2.z < vertex3.z)
         {
           return vertex2.z;
         }
       else
         {
           return vertex3.z;
         }
    }


  /**
   * This method will return the facetNormal value of this object.
   *
   * @return  This object's normal value.
   */
  public PVector getFacetNormal()
  {
    return facetNormal;
  }


  /**
   * This method will return the values of the 3 vertices in this object.
   *
   * @return  A new PVector containing the 3 vertices of this object.
   */
  public PVector[]  getVerticies()
  {
    return new PVector[] { vertex1, vertex2, vertex3 };
  }
}