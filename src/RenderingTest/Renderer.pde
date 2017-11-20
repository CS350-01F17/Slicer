/*
Renderer.pde
 
 This Sketchbook tab holds the definition and implementation of the Renderer interface.
 
  the Renderer Interface provides a uniform way of rendering both G-codes and STls.
  the only function it provides is a function to Render a Model from a POV weather it is
  G-code or STL
 
 Authors:
  Rendring Team
  Hunter Schloss
 */

interface Renderer {
  public PGraphics Render(PGraphics graphic, Model Subject); 
 }