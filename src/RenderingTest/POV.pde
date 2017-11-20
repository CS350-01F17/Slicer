class POV {
  
  private PVector location;
  private PVector focus;
  private float   distance;
  private PVector orientation;
  private float   phi;
  private float   theta;

  public POV(float theta, float phi, float distance, PVector foc)
    {
      this.theta = theta;
      this.phi = phi;
      this.distance = distance;
      
      this.focus = foc;
      
      this.orientation = new PVector();
      this.location = new PVector();
      
      fixAngles();
      CalculteLocation();
    }
    
    
  public void zoom(float delta)
    {
         distance += delta;
         CalculteLocation();
    }
    
  public void setZoom(float zoom)
    {
        this.distance = zoom;
        CalculteLocation();
    }
  
  public void move(PVector delta) 
    {
      this.focus.add(delta);
      CalculteLocation();
    }
  
  public void setpos(PVector newpos) 
    {
      this.focus = newpos;
      CalculteLocation();
    }
  
  //this function is used to orbit the point of view around the focus point
  //theta specifies how much to rotate around the x axis
  //phi specifies how much to rotate around the z axis
  public void Rotate(float theta, float phi) 
    {
      this.theta += theta;
      this.phi += phi;
      fixAngles();
      CalculteLocation(); 
    }
    
    //this function is used to orbit the point of view around the focus point
    //theta specifies the angle of rotation arond the x axis
    //phi spevifies the angle of rotation around the z axis
    public void setAngle(float theta, float phi) 
    {
      this.theta = theta;
      this.phi = phi;
      fixAngles();
      CalculteLocation(); 
    }
  
  public void setFocus(PVector delta)
    {
        focus = delta;
        CalculteLocation();
    }
    
  private void fixAngles()
    {
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
        
    }
  
  private void CalculteLocation()
    {
      location.x = focus.x + distance * sin(radians(theta))*sin(radians(phi));
      location.y = focus.y + distance * -cos(radians(phi));
      location.z = focus.z + distance * -cos(radians(theta))*sin(radians(phi)); 
     
      
    }
  
  public PGraphics setCamera(PGraphics frame){
    frame.camera(location.x, location.y, location.z, focus.x, focus.y, focus.z, 0, 0, -1);
    return frame;
  }
}