/*
FacetRenderer.pde
 
This Sketchbook tab holds the definition and implementation of the Facet Renderer class.
 
the Facet Renderer class is an implintaion of the Renderer interface for rendering Facets 

 
 Authors:
Rendering Team
Hunter Schloss
 */

class FacetRenderer implements Renderer{  
    public PGraphics Render(PGraphics graphic, Model Subject) 
      {     
       ArrayList<Facet> mesh = Subject.getFacets();
       for (Facet facet : mesh) 
         {
              graphic.beginShape();
              PVector[] Triangle = facet.getVerticies();
              graphic.vertex(Triangle[0].x, Triangle[0].y, Triangle[0].z);
              graphic.vertex(Triangle[1].x, Triangle[1].y, Triangle[1].z);
              graphic.vertex(Triangle[2].x, Triangle[2].y, Triangle[2].z);
              graphic.endShape();    
         }
       return graphic;
      }
}