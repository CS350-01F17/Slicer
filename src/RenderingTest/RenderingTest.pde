/*
SlicerProject.pdeP

This Sketchbook tab contains the main code that runs the entire program. 

For more information, view the accompanying READMEs located throughout the project. 

Authors:
*/

//This function is automatically called when the project is run/executed.
// Once this function finished executing, the draw function is called (repeatedly).

PGraphics rendering;
RenderControler vis;
boolean realsed = true;
int i=0;
int j=0;

Model test;

int last;

void setup() {
  size(800, 800, P3D);
  rendering = createGraphics(700, 700, P3D);
  
  vis = new RenderControler(100,100,100);
  vis.ResetCamera();
  
  String adress = "../../40mmcube.stl";
  STLParser parser = new STLParser(adress);
  ArrayList<Facet> data = parser.parseSTL();
  test = new Model(data); 
  vis.CenterModelOnBuildPlate(test);
  vis.FocusOnModel(test);

}

//After the setup function finishes, this function is called repeatedly until the
// program exits.
//Depending on how the project proceeds, we may not use this function, and instead
// treat the setup function as if it were similar to a main function in C/C++/Java.
void draw() {
    // One and ONLY one of these function calls should be uncommented
    
    
  //modelTranslationTest(); // Laggy
    

  //modelScalingTest(); // Seems to work
    
  //rotationTest(); // Z axis rotation isn't correct
    
  //ZoomTest();
    
  //testLayerRenderer();


  
  //testLayerVisibility();
  
  //testFacetRenderer();
    

   
   testVisability();
   
   //modelRotationTest();


}


void testLayerVisibility() {
  vis.SetMode(false);
  test.Slice(0.2, 0.1);  
  for (int i = 0; i < test.getLayerCount(); i++) {
    // Problem: Visualizer is actually a FacetRenderer
    // but we need a LayerRenderer
    LayerRenderer r = (LayerRenderer) vis.GetVisualizer();
    boolean[] barr = r.GetVisible();
    for (int j = 0; j < barr.length; j++) {
      if (j == i) barr[j] = true;
      else barr[j] = false;
    }
    r.SetVisible(barr);

    vis.SetVisualizer(r);
    POV temp = vis.getPOV();
    temp.setZoom(70);
    vis.SetPOV(temp);
}
}


int TVi = 0;
void testVisability()
  {
     test.Slice(.2, .1);
    boolean[] visData = new boolean[test.getLayers().size()];
    POV cam = vis.getPOV();
     cam.setZoom(70);
     vis.SetPOV(cam);
    for(int i=0; i <test.getLayers().size(); i++)
      {
        visData[i] = false;
      }
      visData[TVi] = true;
    vis.SetMode(false);
        
    LayerRenderer temp = (LayerRenderer)vis.getRenderer();  
    temp.setVisability(visData);
    vis.setRenderer(temp);
    vis.Render(test, rendering);
    image(rendering, 50 ,50);
    print(TVi, "\n");
    TVi++;
    if(TVi >= test.getLayers().size())
      {
        TVi=0;
      }
        
  }




void testSliceAndRender() {
  vis.SetMode(false);
  POV temp = vis.getPOV();
  temp.setZoom(70);
  vis.SetPOV(temp);
  test.Slice(0.2, 0.1);
  vis.Render(test, rendering);
     
     
  image(rendering, 50 ,50);
     
}



void testLayerRenderer()
  {
    ArrayList<Line> testLayerRenderer = new ArrayList<Line>();
    testLayerRenderer.add(new Line(1, 1, 10, 10, false));
    testLayerRenderer.add(new Line(10, 10, 20, 15, false));
    testLayerRenderer.add(new Line(20, 15, 30, 10, false));
    testLayerRenderer.add(new Line(30, 10, 25, 5, false));
    testLayerRenderer.add(new Line(25, 5, 20, 10, false));
    testLayerRenderer.add(new Line(20, 10, 10, 5, false));
    ArrayList<Layer> temp = new ArrayList<Layer>();
    temp.add(new Layer(testLayerRenderer, 10));
    test.TESTsetLayers(temp, .2);
    vis.SetMode(false);
    
    vis.Render(test, rendering);
    
    image(rendering, 50 ,50);
    
  }
  
void testFacetRenderer()
  {
    vis.SetMode(true);
    vis.Render(test, rendering);
    image(rendering, 50 ,50);
    
  }


void modelTranslationTest()
  {
    if(mousePressed)
    {
      test.Translate(1,1, vis);
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
    }
    else
      {
      test.Translate(-1,-1, vis);
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
      }
  }

void modelScalingTest()
  {
    if(mousePressed)
    {
      test.Scale(new PVector(1.01,1.01, 1.01), vis);
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
    }
    else
      {
      test.Scale(new PVector(.99, .99, .99), vis);
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
      }
  }



void modelRotationTest()
{
  if (mousePressed) {
    test.Rotate(5.0, 0, 0, vis);
  } else {
    test.Rotate(0, 5.0, 0, vis);
  }
  
  vis.Render(test, rendering);
  image(rendering, 50, 50);
}


void ZoomTest()
  {
   if(mousePressed)
      {
        POV temp = vis.getPOV();
        temp.zoom(1);
        vis.SetPOV(temp);
        vis.Render(test, rendering);
        image(rendering, 50 ,50);
      }
   else
      {
        POV temp = vis.getPOV();
        temp.zoom(-1);
        vis.SetPOV(temp);
        vis.Render(test, rendering);
        image(rendering, 50 ,50);
      }
  }

void rotationTest()
  {
    if(mousePressed)
    {
      POV temp = vis.getPOV();
      temp.Rotate(1, 0);
      vis.SetPOV(temp);
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
    }
    else
      {
        POV temp = vis.getPOV();
      temp.Rotate(0, 1);
      vis.SetPOV(temp);
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
      }
      
  }
    