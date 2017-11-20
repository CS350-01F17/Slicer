/*
RenderControler.pde
This Sketchbook tab holds the definition and implementation of the RenderControler class.
The RenderControler class is used to coridinate to preform all rendering od the model and the build space

 
Authors: Rendering Team (Hunter Schloss)
*/


public class RenderControler
  {    
    private float   Width;
    private float   Length;
    private float   Height;
    
    private POV     Camera;
    
    private Renderer Visualizer;
    
    private boolean RenderFacets;
    
    
    
    
    public RenderControler(float W, float L, float H)
      {
        Width = W;
        Length = L;
        Height = H;
        
        RenderFacets = true;
        Visualizer = new FacetRenderer();
        ResetCamera();
      }
     
    public PGraphics Render(Model Subject, PGraphics frame)
      {
        frame.beginDraw();
        frame.beginCamera();
        Camera.setCamera(frame);
        frame.lights();
        frame.background(255);
        
        if(Subject.isModified() && !RenderFacets)
          {
            Subject.Slice();
          }
        frame.fill(255,0,0);
        frame = Visualizer.Render(frame, Subject);
        
        frame = addBuildSpace(frame);
        frame.endCamera();
         frame.endDraw();
        return frame;
      }
  
    public PGraphics RenderBuildSpace(PGraphics frame)
      {
        frame.beginDraw();
        frame.beginCamera();
        frame = Camera.setCamera(frame);
        frame.lights();
        frame.background(255);
        frame = addBuildSpace(frame);
        frame.endCamera();
        frame.endDraw();
        return frame;
        
      }
      
    private PGraphics addBuildSpace (PGraphics frame)
      {
         frame.noFill();
         
         
         //front wall
         frame.beginShape();
         frame.vertex(0, 0, 0);
         frame.vertex(0, 0, Height);
         frame.vertex(Width, 0, Height);
         frame.vertex(Width, 0, 0);
         frame.endShape();
         
         //left wall
         frame.beginShape();
         frame.vertex(0, 0, 0);
         frame.vertex(0, 0, Height);
         frame.vertex(0, Length, Height);
         frame.vertex(0, Length, 0);
         frame.endShape();
         
         //right wall
         frame.beginShape();
         frame.vertex(Width, 0, 0);
         frame.vertex(Width, 0, Height);
         frame.vertex(Width, Length, Height);
         frame.vertex(Width, Length, 0);
         frame.endShape();
         
         //back wall
         frame.beginShape();
         frame.vertex(0, Length, 0);
         frame.vertex(0, Length, Height);
         frame.vertex(Width, Length, Height);
         frame.vertex(Width, Length, 0);
         frame.endShape();
         
         //floor
         frame.fill(0);
         frame.beginShape();
         frame.vertex(0, 0, 0);
         frame.vertex(0, Length, 0);
         frame.vertex(Width, Length, 0);
         frame.vertex(Width, 0, 0);
         frame.endShape();
         
         
         return frame; 
      }
  
    public void ResetCamera()
      {
        //theta specifies the angle of rotation arond the x axis
        //phi spevifies the angle of rotation around the z axis
        Camera = new POV(90, 60, (Height+Length+Width)/1.5,  new PVector(Width/2, Length/2, Height/2));
      }
     
    public void FocusOnModel(Model Subject)
      {
        Camera.setFocus(Subject.getCenter());
      }
      
    public void CenterModelOnBuildPlate(Model Subject)
      {
        PVector center = Subject.getCenter();
        Subject.Translate(Width/2 - center.x, Length/2 - center.y);
      }
  
    public float[] getDim()
      {
        float[] temp = new float[3];
        temp[0] = Width;
        temp[1] = Length;
        temp[2] = Height;
        return temp;
      }
  
    public void setDim(float w, float l, float h)
      {
        Width = w;
        Length = l;
        Height = h;
      }
      
    public POV getPOV()
      {
         return Camera; 
      }
      
    public void SetPOV(POV Camera)
      {
          this.Camera = Camera;
      }
      
    public void SetMode(boolean mode)
      {
        if(mode != RenderFacets)
          {
            RenderFacets = mode;
            if(RenderFacets)
              {
                Visualizer = new FacetRenderer();
              }
            else
              {
                //Visualizer = new LayerRendrer();
              }            
          }
      }
  }