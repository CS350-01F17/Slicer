/*
LayerRenderer.pde
 
This Sketchbook tab holds the definition and implementation of the Layer Renderer class.
 
the Layer Renderer class is an implintaion of the Renderer interface for rendering a simulation of a GCode file

it contines methods to controle the visability of indvidule layers and weather or not to render the lines when the printer is not exdruding 


 
 Authors:
Rendering Team
Hunter Schloss
 */

class LayerRenderer implements Renderer
  {  
    boolean[] isVisible;
    boolean RenderTravles;
    int numLayers;
    ArrayList<Layer> layers;
    int size; 
    
    int fill;
    int tint;
    
    float LayerHeight;
    
    public LayerRenderer()
      {
        numLayers = 0;
        RenderTravles = false;
      }
      
     public void Load(Model subject, int fill, int tint)
       {
         
         this.fill = fill;
         this.tint = tint;
         layers = subject.getLayers();
         if(layers.size() != numLayers)
           {
             isVisible = new boolean[layers.size()];
             numLayers = layers.size();
             for(int i=0; i<numLayers; i++)
               {
                 isVisible[i] = true;
               }
               RenderTravles = false;
           }
           
         LayerHeight = subject.getLayerHeight();  
           
         size = 0;
         for(Layer curLayer: layers)
           {
             size += curLayer.getCoordinates().size();
           }
       }
       
     public int getSize()
       {
          return size; 
       }
    
     public PShape Render(int i)
       {
         int count = 0;
         int place = 0;
         if(i >= size)
           {
             return createShape();
           }
         while(count <= i)
           {
             count += layers.get(place).getCoordinates().size();
             place ++;
           }
         place --;
         count -= layers.get(place).getCoordinates().size();
         
         
         PShape out = createShape();
         
         if(isVisible[place])
           {
             Layer curLayer = layers.get(place);
             Line curLine   = curLayer.getCoordinates().get(i - count);
             float Height   = curLayer.getHeight();
                 
             if(!curLine.isTravle())
               {
                 out = DrawCylinder(curLine, LayerHeight, Height);
               }
             else
               {
                 out = drawLine(curLine, Height);
               }
           } 
         return out;
       }
    
    
    
     private PShape DrawCylinder(Line path, float LayerHeight, float currentHeight)
       {
         PShape out = createShape();

        
         int sides = 20;
         float angle = 360 / sides;
         float[] temp = path.getPoints();
         float halfHeight =  sqrt(sq(temp[0]-temp[2]) + sq(temp[1]-temp[3]));

          // draw top of the tube
          out.beginShape();
          out.fill(fill,0,0,tint);
          for (int i = 0; i < sides; i++) 
            {
              float x = cos( radians( i * angle ) ) * LayerHeight;
              float y = sin( radians( i * angle ) ) * LayerHeight;
              out.vertex( x, y, 0);
            }
          out.endShape(CLOSE);

          // draw bottom of the tube
          out.beginShape();
          out.fill(fill,0,0,tint);
          for (int i = 0; i < sides; i++)
            {
              float x = cos( radians( i * angle ) ) * LayerHeight;
              float y = sin( radians( i * angle ) ) * LayerHeight;
              out.vertex( x, y, halfHeight);
            }
          out.endShape(CLOSE);
    
          // draw sides
          out.beginShape(TRIANGLE_STRIP);
          out.fill(fill,0,0,tint);
          for (int i = 0; i < sides + 1; i++) 
            {
              float x = cos( radians( i * angle ) ) * LayerHeight;
              float y = sin( radians( i * angle ) ) * LayerHeight;
              out.vertex( x, y, halfHeight);
              out.vertex( x, y, 0);    
            }
          out.endShape(CLOSE);
          
          out.rotateY(radians(90));
          
          PVector placA = new PVector(temp[2] - temp[0], temp[3] - temp[1]);
          
          out.rotateZ(PVector.angleBetween(new PVector(0,1), placA));
          
          out.translate(temp[1], temp[0], currentHeight);
         
          return out;
       } 
       
       private PShape drawLine(Line path, float Height)
         {
           PShape out = createShape();
           float[] temp = path.getPoints();
           out.beginShape(LINE);
           out.vertex(temp[0], temp[1], Height);
           out.vertex(temp[2], temp[3], Height);
           out.endShape(CLOSE);
           return out;
         }
       
  }