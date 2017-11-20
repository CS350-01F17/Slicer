/*
Model.pde

This Sketchbook tab holds the definition and implementation of the Model class.

The Model class serves as a central object to hold the 3d model currently being
 processed. It also contains various methods to manipulate the model, including scaling
 and rotations. Performing these modifications results in the facets that make up the
 object being modified, along with properties that hold information about these
 modifications. Finally, the Model class also provides a method to obtain strings
 that make up an STL file that represents the current state of the model.

Authors: Slicing Team (Andrew Figueroa)
*/

public class Model
{
  private ArrayList<Facet> facets;
  private boolean isModified;
  private PVector scaling;
  private PVector rotation;
  private PVector translation;
  
  public Model(ArrayList<Facet> facets)
  {
    this.facets = facets;
    isModified = false;
    scaling = new PVector(0, 0, 0);
    rotation = new PVector(0, 0, 0);
    translation = new PVector(0, 0, 0);
  }
  
  public ArrayList<Facet> getFacets()
  {
    return facets;
  }
  
  public void setFacets(ArrayList<Facet> newFacets) {
    facets = newFacets;
  }
  
  public PVector getScale()
  {
    return scaling; 
  }
  
  public void setScaling(PVector amount)
  {
    //TODO
    isModified = checkModifications();
  }
  
  public PVector getRoatation()
  {
    return rotation; 
  }
  
  public void setRoation(PVector amount)
  {
    //TODO
    isModified = checkModifications();
  }
  
  public PVector getTranslation()
  {
    return translation;
  }
  
  public void setTranslation(PVector amount)
  {
    translation = amount;
    isModified = checkModifications();
  }
  
  private boolean pVectorEquals(PVector a, PVector b)
  {
    return a.x == b.x && a.y == b.y && a.z == b.z;
  }
  
  private boolean checkModifications()
  {
    PVector origin = new PVector(0, 0, 0);
    return pVectorEquals(scaling, origin) && pVectorEquals(rotation, origin)
           && (pVectorEquals(translation, origin));
  }
}