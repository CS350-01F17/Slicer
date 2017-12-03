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
  private ArrayList<Layer> layers;
  private ArrayList<String> GCode;
  private boolean isModified;

  
  /**
   * Constructor for a Model object given an ArrayList<Facet>.
   *
   * @param  facets  The ArrayList<Facet> to pass into this object.
   */
  
  
    private float layerHeight;
    
    private PVector center;
                            
  
  
    public Model(ArrayList<Facet> facets)
      {
        //set state variables
        isModified = true;      //facets need to be sliced to G-code       
        
        this.facets = facets;  //initilize facets
        calculateCenter();
    }
  
  
  public void Slice(float LH, float InFill)
    {
       layerHeight = LH;
       Slicer alg = new Slicer(facets, layerHeight, InFill);
       layers = alg.sliceLayers();
       GCode = alg.createGCode(layers, 160, 50);    
       synchronize();
       isModified = false;
    }  
  
  
  public void Scale(PVector scale, RenderControler renderer)
    {
      boolean update = false;
      if(renderer.isFocusedOnModel(this))
        {
          update = true;
        }
      //This updates the facet vertex coordinates
      //center does not need to be recomputed because mean of all cordnats wont change
      for (Facet facet : facets) {
        PVector vertices[] = facet.getVerticies();
        for(int i=0; i<3; i++)
          {  
            if(scale.x > 0)
              {
                vertices[i].x *= scale.x;
              }
            if(scale.y > 0)
              {
                vertices[i].y *= scale.y;
              }
            if(scale.z > 0)
              {
                vertices[i].z *= scale.z;
              }
          }
        facet.setVertices(vertices[0], vertices[1], vertices[2]); 
      } 
      isModified = true; //<>//
      calculateCenter();
      if(update)
        {
          renderer.FocusOnModel(this);  
        }
    }
  
  
    //theta specifies the angle of rotation arond the x axis
    //phi spevifies the angle of rotation around the z axis
  public void Rotate(float theta, float phi, float iota, RenderControler renderer)
    {
      if(theta == 0 && phi == 0 && iota == 0)
      {
        return;
      }

      boolean update = false;

      if(renderer.isFocusedOnModel(this))
        {
          update = true;
        }

      theta = theta - int(theta / 360)*360;
      phi = phi -  int(phi / 180)*180;

      if(theta < 0)  
        {
          theta += 360;
        }
      if(phi < 0)
        {
          phi += 180;
        }

      //rotate each facet around the X, Y, and Z axis
      for (Facet facet : facets) // For each facet.
        {
          PVector[] temp = facet.getVerticies();

          for(int i=0; i<3; i++) // For each vector
            {
              //Rotation around the x axis.
              if(theta != 0){
                float x1 = temp[i].x - center.x;
                float z1 = temp[i].z - center.z;

                float x2 = z1 * sin(theta) + x1 * cos(theta);
                float z2 = z1 * cos(theta) - x1 * sin(theta);

                temp[i].x = x2 + center.x;
                temp[i].z = z2 + center.z;
              }

              // Rotation around the y axis.
              if(phi != 0){
                float y1 = temp[i].y - center.y;
                float z1 = temp[i].z - center.z;

                float y2 = y1 * cos(phi) - z1 * sin(phi);
                float z2 = y1 * sin(phi) + z1 * cos(phi);

                temp[i].y = y2 + center.y;
                temp[i].z = z2 + center.z;
              }

              // Rotation around the z axis.
              if(iota != 0){
                float x1 = temp[i].x - center.x;
                float y1 = temp[i].y - center.y;

                float x2 = x1 * cos(iota) - y1 * sin(iota);
                float y2 = x1 * sin(iota) + y1 * cos(iota);

                temp[i].x = x2 + center.x;
                temp[i].y = y2 + center.y;
              }

            }
            facet.setVertices(temp[0], temp[1], temp[2]);

         }

      
       levelModel();

       if(update)
        {
          renderer.FocusOnModel(this);
        } //<>// //<>//
       
    }
 
  public void Translate(float X, float Y, RenderControler renderer)
    {
      if(X == 0 && Y == 0 ){
            return;
        }
        
      boolean update = false;
      if(renderer.isFocusedOnModel(this))
        {
          update = true;
        }
        
      for (Facet facet : facets) 
        {
           PVector[] temp = facet.getVerticies();
           facet.setVertices(temp[0].add(X,Y,0), temp[1].add(X,Y,0), temp[2].add(X,Y,0));
        }
      isModified = true;
      calculateCenter();
      if(update)
        {
          renderer.FocusOnModel(this);  
        }
    }
    
  
  public float getLayerHeight()
    {
       return layerHeight;
    }
   
   
  public void TESTsetLayers(ArrayList<Layer> layers, float LH)
    {
     layerHeight = LH;
     this.layers = layers; 
     isModified = false;
    }
    
    
  public boolean isModified()
    {
      return isModified;
    }
    
    
  public void calculateCenter()
    {
      float AvgX=0;
        float AvgY=0;
        float AvgZ=0;
        int n = facets.size();
        PVector[] temp;
        float tempAvg = 0;
        for (Facet facet : facets) {
           temp = facet.getVerticies();
           tempAvg = 0;
           for(int i=0; i<3; i++){
              tempAvg += temp[i].x / 3;
           }
           AvgX += tempAvg/n;
           
           tempAvg = 0;
           for(int i=0; i<3; i++){
              tempAvg += temp[i].y / 3;
           }
           AvgY += tempAvg/n;
           
           tempAvg = 0;
           for(int i=0; i<3; i++){
              tempAvg += temp[i].z / 3;
           }
           AvgZ += tempAvg/n;
        }
      center =  new PVector(AvgX, AvgY, AvgZ);
    }
    
  private PVector getCenter()
    {
      return center;
    }
      

  
  public ArrayList<Facet> getFacets()
    {
      return facets;
    }
  
  
  public void setFacets(ArrayList<Facet> in)
    {
      facets = in;
      isModified = true;
    }
  
  
  public ArrayList<String> getGCode()
    {
      return GCode;
    }
  
  
  public ArrayList<Layer> getLayers()
    {
      return layers;
    }
  
  
  public void levelModel()
    {
      //find lowest point
      float min = facets.get(0).getLowest();
      for (Facet facet : facets) 
        {
           if(facet.getLowest() < min)
             {
               min = facet.getLowest();
             }
         }
       
       //invert the value of the lowest point 
       //models above the floor are moved down
       //models bellow are moved up
       
       //update all facets 
       for (Facet facet : facets) 
         {
           PVector[] temp = facet.getVerticies();
           facet.setVertices(temp[0].add(0,0,-min), temp[1].add(0,0,-min), temp[2].add(0,0,-min));
         }
         
       calculateCenter();
       isModified = true; //<>//
    }
 
 
 
  //this function will read the gcode from the 
  //adress provided in the constuctor to sycronize the facet reprprsentation to the G-code reprprsentation
  private void synchronize()
    {
      //TODO
    }
    
  }