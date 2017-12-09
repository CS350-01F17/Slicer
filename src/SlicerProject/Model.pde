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

  // Class attributes. 
  private ArrayList<Facet> facets;
  private boolean isModified;
  private PVector scaling;
  private PVector rotation;
  private PVector translation;

  /**
   * Constructor for a Model object given an ArrayList<Facet>.
   *
   * @param  facets  The ArrayList<Facet> to pass into this object.
   */
  public Model(ArrayList<Facet> facets)
  {
    this.facets = facets;
    isModified = false;
    scaling = new PVector(0, 0, 0);
    rotation = new PVector(0, 0, 0);
    translation = new PVector(0, 0, 0);
  }

  /**
   * This method will return the ArrayList<Facet> of this object.
   *
   * @return  The ArrayList<Facet> of this object.
   */
  public ArrayList<Facet> getFacets()
  {
    return facets;
  }

  /**
   * This method will set this object's facet list with the input ArrayList<Facet>.
   *
   * @param  newFacets  The ArrayList<Facet> to pass to this object.
   */
  public void setFacets(ArrayList<Facet> newFacets) {
    facets = newFacets;
  }

  /**
   * this method will return the scaling values for this model.
   *
   * @return  The scaling PVector (x, y, z) values for this model.
   */
  public PVector getScale()
  {
    return scaling;
  }

  /**
   * This method will set the scaling of this model to the input.
   * TODO: Set scaling. This was originally going to be done by the Render group, and this method serves
   * as a placeholder.
   *
   * @param  amount  The PVector (x, y, z) values to set the scaling.
   */
  public void setScaling(PVector amount)
  {
    isModified = checkModifications();
  }

  /**
   * This method will return the rotation values for this model.
   *
   * @return  The rotation PVector(x, y, z) values for this model.
   */
  public PVector getRoatation()
  {
    return rotation;
  }

  /** 
   * This method will set the rotation of this model to the input.
   * TODO: Set rotation. This was originally going to be done by the Render group, and this method serves
   * as a placeholder.
   *
   * @param  amount  The PVector (x, y, z) values to set the rotation.
   */
  public void setRoation(PVector amount)
  {
    isModified = checkModifications();
  }

  /** 
   * This method will return the translation values for this model.
   *
   * @return  The translation PVector (x, y, z) values for this model.
   */
  public PVector getTranslation()
  {
    return translation;
  }

  /**
   * This method will set the translation of this model to the input.
   * TODO: Set translation. This was originally going to be done by the Render group, and this method serves
   * as a placeholder.
   *
   * @param  amount  The PVector (x, y, z) values to set the translation.
   */
  public void setTranslation(PVector amount)
  {
    translation = amount;
    isModified = checkModifications();
  }

  /**
   * This method will determine if one PVector is equal to another based on their 3 values.
   *
   * @param  a  The first PVector.
   * @param  b  The second PVector.
   * @return    Return whether the PVectors are equal based on their (x, y, z) values.
   */
  private boolean pVectorEquals(PVector a, PVector b)
  {
    return a.x == b.x && a.y == b.y && a.z == b.z;
  }

  /**
   * This method will determine if the scaling, rotation, or translation
   * of the model was changed.
   *
   * @return  Whether the scaling, rotation, or translation of the model was changed.
   */
  private boolean checkModifications()
  {
    PVector origin = new PVector(0, 0, 0);
    return pVectorEquals(scaling, origin) && pVectorEquals(rotation, origin)
      && (pVectorEquals(translation, origin));
  }
}