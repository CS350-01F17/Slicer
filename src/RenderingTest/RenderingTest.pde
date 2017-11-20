/*
SlicerProject.pde

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
  
  String adress = "C:\\Users\\200Motels\\Documents\\GitHub\\Slicer_Renderer\\40mmcube.stl";
  STLParser parser = new STLParser(adress);
  ArrayList<Facet> data = parser.parseSTL();
  test = new Model(data, .1, .1);
  
  vis.Render(test, rendering);
  image(rendering, 50 ,50);
  
}

//After the setup function finishes, this function is called repeatedly until the
// program exits.
//Depending on how the project proceeds, we may not use this function, and instead
// treat the setup function as if it were similar to a main function in C/C++/Java.
void draw() {
    modelTranslationTest();
}




void modelTranslationTest()
  {
    if(mousePressed)
    {
      test.Translate(1,1);
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
    }
    else
      {
      test.Translate(-1,-1);
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
      }
  }

void modelScalingTest()
  {
    if(mousePressed)
    {
      test.Scale(new PVector(1.01,1.01, 1.01));
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
    }
    else
      {
      test.Scale(new PVector(.99, .99, .99));
      vis.Render(test, rendering);
      image(rendering, 50 ,50);
      }
  }



void modelRotationTest()
  {
  //TODO
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
    