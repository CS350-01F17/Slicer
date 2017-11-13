/*
STLConverter.pde
 
 This Sketchbook tab holds the definition and implementation of the STLConverter class.
 
 The STLConverter class serves as a way to convert ASCII STL files to Binary STL files. 
 This will, in essence, allow our system to handle the slicing of both ASCII and Binary 
 STL files. If a file is in ASCII format, it will be converted to Binary. Once this
 conversion has taken place, the STL file can then be parsed.
 
 The Binary STL file requires certain data elements in certain spots to consider it binary; 
 in this order:
 - 80 bytes (usually characters) --> Denotes the header
 - 4 bytes (unsigned integer)    --> Denotes the number of facets in the STL file
 - 48 bytes (12 floats)          --> Denotes the x,y,z values of the facet (including normals)
 - 2 bytes (short)               --> Denotes the attribute byte count (this is usually "0" by convention)
 
 Authors: Slicing Team (Paul Canada)
 */

import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.io.FileNotFoundException;
import java.nio.file.InvalidPathException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.BufferOverflowException;


public class STLConverter
{ 
  private String path;
  private byte[] binarySTL = null;
  private int byteCount = 0;
  private ArrayList<String> stringsToConvert = new ArrayList<String>();
  private boolean outputToFile = false;

  /**
   * Default constructor for STLConverter class
   */
  public STLConverter()
  {
    path = null;
  }

  /**
   * Constructor for STLConverter class given an initial path to the file.
   */
  public STLConverter(String path)
  {
    this.path = path;
  }

  /**
   * Constructor for STLConverter class given an initial path to the file and the instruction to automate the process or not.
   */
  public STLConverter(String path, boolean automate)
  {
    this.path = path;

    // If automate is true, convertASCII() will be called when object is instantiated instead
    // of calling it in main.
    if (automate)
    { 
      convertASCII();
    }
  }


  /**
   * This method will handle converting the ASCII floats to binary floats.
   * Simply call object.convertASCII() to grab all the floats from the
   * STL file and convert them to their respective byte form; also
   * adding in extra necessary data such as 80 bytes for the header, 4 bytes
   * for the number of facets in the file, and 2 bytes for an attribute byte count.
   * By convention, the attribute byte count is always 0.
   
   * @return    The byte array containing the binary STL data.
   * @see        STLConverer.readInLines()
   */
  public byte[] convertASCII()
  {
    short attribute = 0;
    int attributeCount = 0;
    int facetCount = 0;

    // Read in all floats from ASCII STL file.
    println("Reading file...");
    if (readInLines()) {
      // Return null if the Arraylist<String> is empty, as there is an error.
      if (stringsToConvert.isEmpty())
      {
        return null;
      }

      facetCount = stringsToConvert.size() / 12;

      // Create the ByteBuffer to store all bytes before assigning to byte[]
      println("Allocating space in the ByteBuffer...");
      ByteBuffer buffer = ByteBuffer.allocate(byteCount);
      buffer.order(ByteOrder.LITTLE_ENDIAN);

      // Fill in 80 bytes for the header. At the moment, just fills in with 40 chars, as a char in this sense is 2 bytes.
      println("Filling in the header...");
      for (int i = 0; i < 80; i++)
      {
        try 
        {
          buffer.put(byte(0));
        } 
        catch (BufferOverflowException e)
        {
          println("Error writing header bytes to byte buffer.");
          return null;
        }
      }


      /**
       * Fill in 4 bytes for the amount of triangles in the STL file.
       * This number can be computed by taking the size of the stringsToConvert ArrayList<String> and dividing it by 12
       * as 1 triangle will consist of 9 floats, not including the normal that consists of 3 floats. 
       * E.g. STL with 3 facets will yield 36 floats (27 for the vertices, and 9 for the normals). 36 / 12 = 3, which gives us 
       * the number of facets. 
       */
      try
      {
        buffer.putInt(facetCount);
      }
      catch (BufferOverflowException e)
      {
        println("Error writing number of triangles in the STL file to byte buffer.");
        return null;
      }

      /* Loop through each float (aka "line") and write it to the
       * Byte Buffer. For every 12 floats, include a 2-byte attribute
       * count.
       */
      println("Converting floats to bytes...");
      for (String line : stringsToConvert)
      {

        try
        {
          buffer.putFloat(float(line));
          attributeCount++;

          // Once count is 12, we have completed a facet and need to add the attribute count.
          if (attributeCount == 12)
          {
            attributeCount = 0;
            buffer.putShort(attribute);
          }
        } 
        catch (BufferOverflowException e)
        {
          println("Error writing float:" + float(line) + " to byte buffer.");
          return null;
        }
      }

      // Add all the bytes from the ByteArrayOutputStream to our byte array, which will
      // be sent to the STLParser. 
      println("Moving bytes from ByteBuffer to byte[]...");
      byte convertedBytes[] = buffer.array();


      // Attempt to flush Byte Buffer for later use, if needed.
      buffer.clear();

      // Write converted binarySTL to file
      if (outputToFile)
      {
        try {
          
          String outputDirectory = System.getProperty("user.dir") + "\\binary_" + path;
          println("Writing converted binary file to " + outputDirectory + "...");
          
          // Output directory
          Files.write(Paths.get(outputDirectory), convertedBytes);
        }
        catch (IOException e)
        {
          println("Error writing converted file to disk. Change the output directory if having issues.");
        }
        catch (InvalidPathException ie)
        {
          println("Error writing converted file to directory. Change output directory.");
        }
      }


      // Assign contents of Byte Buffer to STLConverter's binarySTL byte[]
      binarySTL = convertedBytes;
      println("Conversion from ASCII to Binary is complete.");
      return convertedBytes;
    } else 
    {

      println("Error reading in STL file.");
      return null;
    }
  }


  /**
   * This method sets the path of the STLConverter object.
   * @param    path The path to the STL file.
   */
  public void setPath(String path)
  {
    this.path = path;
  }



  /*
   * This method checks if the binarySTL attribute is null or not.
   * @return    True if the binarySTL lbyte array is empty, false otherwise.
   */
  public boolean checkIfNullBinary()
  {
    return (binarySTL == null);
  }



  /**
   * This method will read in lines from the file whose path is given
   * in the constructor, or manually set using the setPath(...) method.
   * A regex pattern will be applied to each line to search for any
   * float that is in scientific or normal form.
   * e.g. -2.143e-001 ; 7.1394 ; 0.0
   *
   * @return    True denoting if the operation finished successfully, false otherwise.
   */
  public boolean readInLines()
  {

    String[] lines = loadStrings(path);
    ArrayList<String> newLines = new ArrayList<String>();

    // Byte sizes of variables that will need to be allocated for the ByteBuffer
    final int floatBytes = 4;
    final int shortBytes = 2;
    final int headerBytes = 80;
    int attributeCounter = 0;

    Pattern p = Pattern.compile("-?[0-9]+\\.[0-9]+[Ee]?[-+]?[0-9]*|-?[0-9]+"); // Matches normal floats, scientific notation floats, or single integers.
    Matcher m;

    // Preliminary check to make sure lines is not empty
    if (lines == null || lines.length == 0)
    {
      return false;
    }

    // Reserve 80 bytes for the header, and 4 bytes for the number of facets
    byteCount = headerBytes + floatBytes;

    println("Converting strings to floats...");

    // Loop through each line and apply the regex matching
    for (int i = 0; i < lines.length; i++)
    {
      m = p.matcher(lines[i]);

      // Add matched content (matcher group()) to the private ArrayList<String>
      while (m.find())
      {
        newLines.add(m.group());

        // Reserve 4 bytes for the float
        byteCount += floatBytes;
        attributeCounter++;

        if (attributeCounter == 12)
        {
          // Reserve 2 bytes for the attribute count
          byteCount += shortBytes;
          attributeCounter = 0;
        }
      }
    }

    // Check to make sure operation was successful and we found matches. If not, return false as it must be an error.
    if (newLines.size() == 0)
    {
      println("Error with reading in lines. Could not find any matches to pattern.");
      return false;
    } else 
    {
      stringsToConvert = newLines;
      return true;
    }
  }
}