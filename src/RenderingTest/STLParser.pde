/*
STLParser.pde

This Sketchbook tab holds the definition and implementation of the STLParser class.

The STLParser class is responsible for reading in an STL file and interpreting the facets
 located within the file. The STLParser class automatically determines whether a given STL
 file is a Binary STL or an ASCII STL.
 
Due to the use of ArrayList to hold Facets, it is not possible to handle STLs that contain
 more than 2^31 - 1 facets. Parsing STL files that contain tens or hundreds of millions of
 facets may require increasing the memory allowed to the sketch in the Preferences window.
 
Authors: Slicing Team (Andrew Figueroa)
*/

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.BufferUnderflowException;

public class STLParser
{
  private final String filePath;
  
  /**
   * Constructs an STLParser object given a file path to a .stl file. The path and file
   * pointed to by the path are not checked for validity until STLParser.parseSTL() is called.
   * <p>
   * If the .stl file pointed to can be is an ASCII STL file, the STLParser class first
   * converts it to a Binary STL using the STLConverter class.
   *
   * @param  path  an absolute file path to a Binary or ASCII STL file
   */
  public STLParser(String path)
  {
    if (path == null)
    {
      filePath = "";
    }
    else
    {
      filePath = path;
    }
  }
  
  /**
   * Parses the .stl file at the location given during the construction of the object. Does
   * not throw any exceptions or return error codes. If an error occurs during parsing, null
   * is returned. Currently, if an error is detected, debug information may be printed to 
   * System.out.
   * <p>
   * This method can be reused to obtain a clean copy of the facets from the original STL file,
   * provided that the original .stl file is still accessible. 
   * 
   * @return  an ArrayList<Facet> of facets that were represented by the .stl file
   * @see     STLParser.STLParser()
   */
  public ArrayList<Facet> parseSTL()
  {
    ArrayList<Facet> facets = null;
    
    //read in file from disk, contents is set to null if an error occured
    byte[] contents = loadBytes(filePath);
    
    //convert any ASCII STL to Binary STL
    if (contents != null && contents.length >= 5)
    {
      //detects an ASCII STL by checking if the first 5 bytes match "solid"
      if (contents[0] == 's' && contents[1] == 'o' && contents[2] == 'l' && contents[3] == 'i'
          && contents[4] == 'd')
      {
        STLConverter converter = new STLConverter(filePath);
        contents = converter.convertASCII();
      }
    }
    
    //interpret facets
    facets = interpretBinarySTL(contents);
    
    return facets;
  }

  /**
   * Interprets (parses) an array of bytes as a Binary STL file. If the number of facets
   * reported in the STL file does not match the number of facets interpreted, then null
   * is returned.
   *
   * @param  stlContents  an array of bytes that represents the contents of a Binary STL file
   * @return              an ArrayList<Facet> of facets that were represented by the contents
   */
  private ArrayList<Facet> interpretBinarySTL(byte[] stlContents)
  {
    ArrayList<Facet> facets = null;
    final int STL_HEADER_SIZE = 80; //num of bytes in Binary STL header
    
    if (stlContents != null && stlContents.length > STL_HEADER_SIZE)
    {
      long facetCount = 0;
      
      //set up ByteBuffer to process data, starting after the Binary STL header
      ByteBuffer buffer = ByteBuffer.wrap(stlContents, STL_HEADER_SIZE,
                                          stlContents.length - STL_HEADER_SIZE);
      buffer.order(ByteOrder.LITTLE_ENDIAN); //STL files are little endian by convention
      
      //process data within stlContents through ByteBuffer
      try {
        //STL files store facet count as UINT32, Java/Processing does not have unsigned types
        facetCount = Integer.toUnsignedLong(buffer.getInt());
        println("STLParser.interpretBinarySTL(): STL Facet count: " + facetCount); //TODO: remove after development
        
        if (facetCount < Integer.MAX_VALUE) //we cannot handle more than 2^31-1 facets due to ArrayList
        {
          facets = new ArrayList<Facet>();
          facets.ensureCapacity((int)facetCount);
          
          while (true) //until exception occurs (BufferUnderflowException expected at end)
          {
            PVector normal = new PVector(buffer.getFloat(), buffer.getFloat(), buffer.getFloat());
            PVector v1 = new PVector(buffer.getFloat(), buffer.getFloat(), buffer.getFloat());
            PVector v2 = new PVector(buffer.getFloat(), buffer.getFloat(), buffer.getFloat());
            PVector v3 = new PVector(buffer.getFloat(), buffer.getFloat(), buffer.getFloat());
            buffer.getShort(); //skip STL "attribute byte count" property
            
            facets.add(new Facet(v1, v2, v3, normal));
          }
        }
        else
        {
          System.out.println("STLParser.interpretBinarySTL(): Could not parse STL as it contained" +
                             " over Integer.MAX_VALUE (2^31 - 1) facets");
        }
      }
      catch (BufferUnderflowException ex)
      {
        if (facets == null)
        {
          System.out.println("STLParser.interpretBinarySTL(): Could not read facet count property" + 
                             " of stlContents. This may not be a valid STL file");
        }
        else if (facetCount != facets.size())
        {
          System.out.println("STLParser.interpretBinarySTL(): Facet count property did not match" + 
                             " number of interpreted facets. This may not be a valid STL file");
        }
      }
    }
    else
    {
      System.out.println("STLParser.interpretBinarySTL(): stlContents was not a valid STL file" + 
                         " (null or length < 80 bytes).");
    }
    return facets;
  }
}