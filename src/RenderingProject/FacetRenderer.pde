/*
FacetRenderer.pde
 
This Sketchbook tab holds the definition and implementation of the Facet Renderer class.
 
the Facet Renderer class is an implintaion of the Renderer interface for rendering Facets 

 
 Authors:
Rendering Team
Hunter Schloss
 */

class FacetRenderer implements Renderer{  
    ArrayList<Facet> Mesh;
    int fill;
    int tint;
  
    public void Load(Model Subject, int fill, int tint)
      {
        Mesh = Subject.getFacets();
        this.fill = fill;
        this.tint = tint;
      }
      
    public int getSize()
      {
        return Mesh.size();
      }
      
    public PShape Render(int i) 
      {     
       PShape out = createShape();
       if(i >= Mesh.size())
         {
            return out; 
         }
       PVector[] Triangle = Mesh.get(i).getVerticies();

           
       out.beginShape();
       out.fill(fill, 0, 0, tint);
       out.vertex(Triangle[0].x, Triangle[0].y, Triangle[0].z);     
       out.vertex(Triangle[1].x, Triangle[1].y, Triangle[1].z);   
       out.vertex(Triangle[2].x, Triangle[2].y, Triangle[2].z);  
       out.endShape();
       return out;
     }
       
}