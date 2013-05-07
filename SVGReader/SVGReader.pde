
/**
 *  Reads an SVG image file, converts the path data into 
 *  a list of coordinates, then sends the coordinates
 *  over the serial connection to an arduino.
 *  NOTE: The arduino must have a compatible program. 
 *  (see sendData() method below)
 *  
 *  ALSO: This does not yet support quadratic Bezier curves(Q,q,T,t commands)
 *  but I've never seen those in Inkscape or Gimp files
 *  Does not yet support "transform" commands, though it would be
 *  oh so simple to add this.
 *  
 *  Copyright 2012 Eric Heisler
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 3 as published by
 *  the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  The SVG vector graphics file type is specified by and belongs to W3C
 */
import processing.serial.*;
import java.io.*;

//////////////////////////////////////////////
// Set these variables directly before running
//////////////////////////////////////////////
final String serialPort = "COM9"; // the name of the USB port
final String filePath = "C:/Users/je7sen/Desktop/test2.svg"; // the SVG file path
final double precision = 2; // precision for interpolating curves (smaller = finer)
final double maxdim = 50.0; // maximum dimension in mm (either height or width)
boolean sendIt = false; // true=sends the data, false=just draws to screen
//////////////////////////////////////////////

ArrayList<Point> allpoints;
ArrayList<Integer> zchanges;
boolean zdown;
Serial sPort; 

void setup() {
  size(600, 600);
  allpoints = new ArrayList<Point>();
  zchanges = new ArrayList<Integer>();
  zdown = false;
  // read the data file
  readData(filePath);
  if (allpoints.size()==0) {
    println("There was an error in the data file");
    return;
  }

  sPort = new Serial(this, serialPort, 9600);
  if(sPort==null && sendIt){
    println("couldn't find serial port");
  }
}



// reads the file
void readData(String fileName) {

  File file=new File(fileName);
  BufferedReader br=null;
  allpoints = new ArrayList<Point>();
  zchanges = new ArrayList<Integer>();
  
  try {
    br=new BufferedReader(new FileReader(file));
  }catch(Exception e){
    println("error opening file");
    e.printStackTrace();
  }
  
  try{
    String text=null;
    int ind = -1;
    boolean foundPath = false;
    boolean foundPData = false;
    String pstring = null; // holds the full path data in a string
    String[] pdata = null; // each element of the path data
    Point relpt = new Point(0.0, 0.0); // for relative commands
    Point startpt = new Point(0.0, 0.0); // for z commands
    
    while ( (text=br.readLine())!=null) {
      // search for the beginning of a path: "<path"
      if(!foundPath){
        ind = text.indexOf("<path");
        if(ind < 0){ 
          continue; 
        }else{
          foundPath = true;
        }
      }
      // we found a path. Now search for the path data
      // NOTE: this will typically work for Inkscape and Gimp. 
      // Not guaranteed to work for all SVG editors
      if(!foundPData){
        ind = text.indexOf("d=\"M ");
        if(ind < 0){
          ind = text.indexOf("d=\"m ");
          if(ind < 0){
            continue;
          }else{
            foundPData = true;
            ind = text.indexOf('m');
          }
        }else{
          foundPData = true;
          ind = text.indexOf('M');
        }
      }
      // now we are on the first line of path data
      // let's read in the whole path data into one long string bastard
      pstring = text.substring(ind);
      if(pstring.indexOf("\"") >= 0){
        foundPData = false;
        pstring = pstring.substring(0, pstring.indexOf("\""));
      }
      while(foundPData){
        pstring = pstring + br.readLine();
        if(pstring.indexOf("\"") >= 0){
          foundPData = false;
          pstring = pstring.substring(0, pstring.indexOf("\""));
        }
      }
      // now split the string into parts
      pdata = splitTokens(pstring, ", TAB");
      
      // now the task of parsing and interpolating
      int mode = -1; // 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 = M,m,L,l,H,h,V,v,C,c,S,s,A,a,Z,z
      Point cntrlpt = null; // special point for s commands
      ArrayList<Point> pathpoints = new ArrayList<Point>();
      for(int i=0; i<pdata.length; i++){
        if(mode == 0){ mode = 2; }  // only one M/m command at a time
        if(mode == 1){ mode = 3; }
        if(pdata[i].charAt(0) == 'M'){
          mode = 0;
          i++;
        }else if(pdata[i].charAt(0) == 'm'){
          mode = 1;
          i++;
        }else if(pdata[i].charAt(0) == 'L'){
          mode = 2;
          i++;
        }else if(pdata[i].charAt(0) == 'l'){
          mode = 3;
          i++;
        }else if(pdata[i].charAt(0) == 'H'){
          mode = 4;
          i++;
        }else if(pdata[i].charAt(0) == 'h'){
          mode = 5;
          i++;
        }else if(pdata[i].charAt(0) == 'V'){
          mode = 6;
          i++;
        }else if(pdata[i].charAt(0) == 'v'){
          mode = 7;
          i++;
        }else if(pdata[i].charAt(0) == 'C'){
          mode = 8;
          i++;
        }else if(pdata[i].charAt(0) == 'c'){
          mode = 9;
          i++;
        }else if(pdata[i].charAt(0) == 'S'){
          if(mode < 8 || mode > 11){
            cntrlpt = relpt;
          }
          mode = 10;
          i++;
        }else if(pdata[i].charAt(0) == 's'){
          if(mode < 8 || mode > 11){
            cntrlpt = relpt;
          }
          mode = 11;
          i++;
        }else if(pdata[i].charAt(0) == 'A'){
          mode = 12;
          i++;
        }else if(pdata[i].charAt(0) == 'a'){
          mode = 13;
          i++;
        }else if(pdata[i].charAt(0) == 'Z'){
          mode = 14;
          //i++; don't need this
        }else if(pdata[i].charAt(0) == 'z'){
          mode = 15;
          //i++; don't need this
        }else if(pdata[i].charAt(0) == 'Q' || pdata[i].charAt(0) == 'q' || pdata[i].charAt(0) == 'T' || pdata[i].charAt(0) == 't'){
          println("Q,q,T,t not supported");
          return;
        }else{
          // repeated commands do not need repeated letters
        }
        
        if(mode == 0){
          // lift and lower the pen
          zchanges.add(allpoints.size()+pathpoints.size());
          zchanges.add(-allpoints.size()-pathpoints.size()-1);
          // this is followed by 2 numbers
          double tmpx = Double.valueOf(pdata[i]).doubleValue();
          double tmpy = Double.valueOf(pdata[i+1]).doubleValue();
          relpt = new Point(tmpx, tmpy);
          startpt = new Point(tmpx, tmpy);
          pathpoints.add(new Point(tmpx, tmpy));
          i++;
        }else if(mode == 1){
          // lift and lower the pen
          zchanges.add(allpoints.size()+pathpoints.size());
          zchanges.add(-allpoints.size()-pathpoints.size()-1);
          double x = 0.0;
          double y = 0.0;
          if(pathpoints.size() > 0){
            x = relpt.x;
            y = relpt.y;
          }
          // this is followed by 2 numbers
          double tmpx = x + Double.valueOf(pdata[i]).doubleValue();
          double tmpy = y + Double.valueOf(pdata[i+1]).doubleValue();
          relpt = new Point(tmpx, tmpy);
          startpt = new Point(tmpx, tmpy);
          pathpoints.add(new Point(tmpx, tmpy));
          i++;
        }else if(mode == 2){
          // this is followed by 2 numbers
          double tmpx = Double.valueOf(pdata[i]).doubleValue();
          double tmpy = Double.valueOf(pdata[i+1]).doubleValue();
          relpt = new Point(tmpx, tmpy);
          pathpoints.add(new Point(tmpx, tmpy));
          i++;
        }else if(mode == 3){
          // this is followed by 2 numbers
          double tmpx = relpt.x + Double.valueOf(pdata[i]).doubleValue();
          double tmpy = relpt.y + Double.valueOf(pdata[i+1]).doubleValue();
          relpt = new Point(tmpx, tmpy);
          pathpoints.add(new Point(tmpx, tmpy));
          i++;
        }else if(mode == 4){
          // this is followed by 1 number
          pathpoints.add(new Point(Double.valueOf(pdata[i]).doubleValue(), relpt.y));
          relpt = new Point(Double.valueOf(pdata[i]).doubleValue(), relpt.y);
        }else if(mode == 5){
          // this is followed by 1 number
          double tmpx = relpt.x + Double.valueOf(pdata[i]).doubleValue();
          pathpoints.add(new Point(tmpx, relpt.y));
          relpt = new Point(tmpx, relpt.y);
        }else if(mode == 6){
          // this is followed by 1 number
          pathpoints.add(new Point(relpt.x, Double.valueOf(pdata[i]).doubleValue()));
          relpt = new Point(relpt.x, Double.valueOf(pdata[i]).doubleValue());
        }else if(mode == 7){
          // this is followed by 1 number
          double tmpy = relpt.y + Double.valueOf(pdata[i]).doubleValue();
          pathpoints.add(new Point(relpt.x, tmpy));
          relpt = new Point(relpt.x, tmpy);
        }else if(mode == 8){
          // this is followed by 6 numbers
          double x = relpt.x;
          double y = relpt.y;
          double xc1 = Double.valueOf(pdata[i]).doubleValue();
          double yc1 = Double.valueOf(pdata[i+1]).doubleValue();
          double xc2 = Double.valueOf(pdata[i+2]).doubleValue();
          double yc2 = Double.valueOf(pdata[i+3]).doubleValue();
          double px = Double.valueOf(pdata[i+4]).doubleValue();
          double py = Double.valueOf(pdata[i+5]).doubleValue();
          cntrlpt = new Point(x + x-xc2, y + y-yc2);
          pathpoints.addAll(interpolateCurve(relpt, new Point(xc1, yc1), new Point(xc2, yc2), new Point(px, py)));
          relpt = new Point(px, py);
          i += 5;
        }else if(mode == 9){
          // this is followed by 6 numbers
          double x = relpt.x;
          double y = relpt.y;
          double xc1 = x + Double.valueOf(pdata[i]).doubleValue();
          double yc1 = y + Double.valueOf(pdata[i+1]).doubleValue();
          double xc2 = x + Double.valueOf(pdata[i+2]).doubleValue();
          double yc2 = y + Double.valueOf(pdata[i+3]).doubleValue();
          double px = x + Double.valueOf(pdata[i+4]).doubleValue();
          double py = y + Double.valueOf(pdata[i+5]).doubleValue();
          cntrlpt = new Point(x + x-xc2, y + y-yc2);
          pathpoints.addAll(interpolateCurve(relpt, new Point(xc1, yc1), new Point(xc2, yc2), new Point(px, py)));
          relpt = new Point(px, py);
          i += 5;
        }else if(mode == 10){
          // this is followed by 4 numbers
          double x = relpt.x;
          double y = relpt.y;
          double xc2 = Double.valueOf(pdata[i]).doubleValue();
          double yc2 = Double.valueOf(pdata[i+1]).doubleValue();
          double px = Double.valueOf(pdata[i+2]).doubleValue();
          double py = Double.valueOf(pdata[i+3]).doubleValue();
          pathpoints.addAll(interpolateCurve(relpt, cntrlpt, new Point(xc2, yc2), new Point(px, py)));
          relpt = new Point(px, py);
          i += 3;
          cntrlpt = new Point(x + x-xc2, y + y-yc2);
        }else if(mode == 11){
          // this is followed by 4 numbers
          double x = relpt.x;
          double y = relpt.y;
          double xc2 = x + Double.valueOf(pdata[i]).doubleValue();
          double yc2 = y + Double.valueOf(pdata[i+1]).doubleValue();
          double px = x + Double.valueOf(pdata[i+2]).doubleValue();
          double py = y + Double.valueOf(pdata[i+3]).doubleValue();
          pathpoints.addAll(interpolateCurve(relpt, cntrlpt, new Point(xc2, yc2), new Point(px, py)));
          relpt = new Point(px, py);
          i += 3;
          cntrlpt = new Point(x + x-xc2, y + y-yc2);
        }else if(mode == 12){
          // this is followed by 7 numbers
          double rx = Double.valueOf(pdata[i]).doubleValue();
          double ry = Double.valueOf(pdata[i+1]).doubleValue();
          double xrot = Double.valueOf(pdata[i+2]).doubleValue();
          boolean bigarc = Integer.valueOf(pdata[i+3]) > 0;
          boolean sweep = Integer.valueOf(pdata[i+4]) > 0;
          double px = Double.valueOf(pdata[i+5]).doubleValue();
          double py = Double.valueOf(pdata[i+6]).doubleValue();
          pathpoints.addAll(interpolateArc(relpt, rx, ry, xrot, bigarc, sweep, new Point(px, py)));
          relpt = new Point(px, py);
          i += 6;
        }else if(mode == 13){
          // this is followed by 7 numbers
          double x = relpt.x;
          double y = relpt.y;
          double rx = Double.valueOf(pdata[i]).doubleValue();
          double ry = Double.valueOf(pdata[i+1]).doubleValue();
          double xrot = Double.valueOf(pdata[i+2]).doubleValue();
          boolean bigarc = Integer.valueOf(pdata[i+3]) > 0;
          boolean sweep = Integer.valueOf(pdata[i+4]) > 0;
          double px = x + Double.valueOf(pdata[i+5]).doubleValue();
          double py = y + Double.valueOf(pdata[i+6]).doubleValue();
          pathpoints.addAll(interpolateArc(relpt, rx, ry, xrot, bigarc, sweep, new Point(px, py)));
          relpt = new Point(px, py);
          i += 6;
        }else if(mode == 14){
          double tmpx = startpt.x;
          double tmpy = startpt.y;
          pathpoints.add(new Point(tmpx, tmpy));
          relpt = new Point(tmpx, tmpy);
        }else if(mode == 15){
          double tmpx = startpt.x;
          double tmpy = startpt.y;
          pathpoints.add(new Point(tmpx, tmpy));
          relpt = new Point(tmpx, tmpy);
        }
      }
      // here we have completed this path. Yay!
      allpoints.addAll(pathpoints);
      foundPath = false;
      println("subpath complete, points: "+String.valueOf(pathpoints.size())+" mode: "+mode);
    }
  }
   
    
  // here we have read in all the paths in the file
  
  catch(FileNotFoundException e) {
    e.printStackTrace();
  }
  catch(IOException e) {
    e.printStackTrace();
  }
  finally {
    try {
      if (br != null) {
        br.close();
      }
    } 
    catch (IOException e) {
      e.printStackTrace();
    }
  }
 println("total points:"+allpoints.size());
  for(int h=0; h<allpoints.size();h++)
  {
    println("point "+h+" x:"+allpoints.get(h).x);
    println("point "+h+" y:"+allpoints.get(h).y);}
   
   if(allpoints.size()>0)
  {
   sendIt = true;
  }
   else
  {
   sendIt = false;
  } 
    
    
}

/*
* Interpolate the cubic Bezier curves (commands C,c,S,s)
*/
ArrayList<Point> interpolateCurve(Point p1, Point pc1, Point pc2, Point p2) {

  ArrayList<Point> pts = new ArrayList<Point>();

  pts.add(0, p1);
  pts.add(1, p2);
  double maxdist = Math.sqrt((p1.x-p2.x)*(p1.x-p2.x) + (p1.y-p2.y)*(p1.y-p2.y));
  double interval = 1.0;
  double win = 0.0;
  double iin = 1.0;
  int segments = 1;
  double tmpx, tmpy;

  while (maxdist > precision && segments < 1000) {
    interval = interval/2.0;
    segments = segments*2;

    for (int i=1; i<segments; i+=2) {
      win = 1-interval*i;
      iin = interval*i;
      tmpx = win*win*win*p1.x + 3*win*win*iin*pc1.x + 3*win*iin*iin*pc2.x + iin*iin*iin*p2.x;
      tmpy = win*win*win*p1.y + 3*win*win*iin*pc1.y + 3*win*iin*iin*pc2.y + iin*iin*iin*p2.y;
      pts.add(i, new Point(tmpx, tmpy));
    }
    if(segments > 3){
      maxdist = 0.0;
      for (int i=0; i<pts.size()-2; i++) {
        // this is the deviation from a straight line between 3 points
        tmpx = (pts.get(i).x-pts.get(i+1).x)*(pts.get(i).x-pts.get(i+1).x) + (pts.get(i).y-pts.get(i+1).y)*(pts.get(i).y-pts.get(i+1).y) - ((pts.get(i).x-pts.get(i+2).x)*(pts.get(i).x-pts.get(i+2).x) + (pts.get(i).y-pts.get(i+2).y)*(pts.get(i).y-pts.get(i+2).y))/4.0;
        if (tmpx > maxdist) {
          maxdist = tmpx;
        }
      }
      maxdist = Math.sqrt(maxdist);
    }
  }

  return pts;
}

/*
* Interpolate the elliptical arcs (commands A,a)
*/
ArrayList<Point> interpolateArc(Point p1, double rx, double ry, double xrot, boolean bigarc, boolean sweep, Point p2) {

  ArrayList<Point> pts = new ArrayList<Point>();

  pts.add(0, p1);
  pts.add(1, p2);
  // if the ellipse is too small to draw
  if(Math.abs(rx) <= precision || Math.abs(ry) <= precision){
    return pts;
  }
  
  // Now we begin the task of converting the stupid SVG arc format 
  // into something actually useful (method derived from SVG specification)
  
  // convert xrot to radians
  xrot = xrot*PI/180.0;
  
  // radius check
  double x1 = Math.cos(xrot)*(p1.x-p2.x)/2.0 + Math.sin(xrot)*(p1.y-p2.y)/2.0;
  double y1 = -Math.sin(xrot)*(p1.x-p2.x)/2.0 + Math.cos(xrot)*(p1.y-p2.y)/2.0;
  
  rx = Math.abs(rx);
  ry = Math.abs(ry);
  double rchk = x1*x1/rx/rx + y1*y1/ry/ry;
  if(rchk > 1.0){
    rx = Math.sqrt(rchk)*rx;
    ry = Math.sqrt(rchk)*ry;
  }
  
  // find the center
  double sq = (rx*rx*ry*ry - rx*rx*y1*y1 - ry*ry*x1*x1)/(rx*rx*y1*y1 + ry*ry*x1*x1);
  if(sq < 0){
    sq = 0;
  }
  sq = Math.sqrt(sq);
  double cx1 = 0.0;
  double cy1 = 0.0;
  if(bigarc==sweep){
    cx1 = -sq*rx*y1/ry;
    cy1 = sq*ry*x1/rx;
  }else{
    cx1 = sq*rx*y1/ry;
    cy1 = -sq*ry*x1/rx;
  }
  double cx = (p1.x+p2.x)/2.0 + Math.cos(xrot)*cx1 - Math.sin(xrot)*cy1;
  double cy = (p1.y+p2.y)/2.0 + Math.sin(xrot)*cx1 + Math.cos(xrot)*cy1;
  
  // find angle start and angle extent
  double theta = 0.0;
  double dtheta = 0.0;
  double ux = (x1-cx1)/rx;
  double uy = (y1-cy1)/ry;
  double vx = (-x1-cx1)/rx;
  double vy = (-y1-cy1)/ry;
  double thing = Math.sqrt(ux*ux + uy*uy);
  double thing2 = thing * Math.sqrt(vx*vx + vy*vy);
  if(thing == 0){
    thing = 1e-7;
  }
  if(thing2 == 0){
    thing2 = 1e-7;
  }
  if(uy < 0){
    theta = -Math.acos(ux/thing);
  }else{
    theta = Math.acos(ux/thing);
  }
  
  if(ux*vy-uy*vx < 0){
    dtheta = -Math.acos((ux*vx+uy*vy)/thing2);
  }else{
    dtheta = Math.acos((ux*vx+uy*vy)/thing2);
  }
  dtheta = dtheta%(2*PI);
  if(sweep && dtheta < 0){
    dtheta += 2*PI;
  }
  if(!sweep && dtheta > 0){
    dtheta -= 2*PI;
  }
  
  // Now we have converted from stupid SVG arcs to something useful.
  
  double maxdist = 100;
  double interval = dtheta;
  int segments = 1;
  double tmpx, tmpy;

  while (maxdist > precision && segments < 1000) {
    interval = interval/2.0;
    segments = segments*2;

    for (int i=1; i<segments; i+=2) {
      tmpx = cx + rx*Math.cos(theta+interval*i)*Math.cos(xrot) - ry*Math.sin(theta+interval*i)*Math.sin(xrot);
      tmpy = cy + rx*Math.cos(theta+interval*i)*Math.sin(xrot) + ry*Math.sin(theta+interval*i)*Math.cos(xrot);
      pts.add(i, new Point(tmpx, tmpy));
    }

    if(segments > 3){
      maxdist = 0.0;
      for (int i=0; i<pts.size()-2; i++) {
        // this is the deviation from a straight line between 3 points
        tmpx = (pts.get(i).x-pts.get(i+1).x)*(pts.get(i).x-pts.get(i+1).x) + (pts.get(i).y-pts.get(i+1).y)*(pts.get(i).y-pts.get(i+1).y) - ((pts.get(i).x-pts.get(i+2).x)*(pts.get(i).x-pts.get(i+2).x) + (pts.get(i).y-pts.get(i+2).y)*(pts.get(i).y-pts.get(i+2).y))/4.0;
        if (tmpx > maxdist) {
          maxdist = tmpx;
        }
      }
      maxdist = Math.sqrt(maxdist);
    }
  }

  return pts;
}

// a convenience class for storing 2-D coordinates
class Point {
  public double x;
  public double y;
  Point(double nx, double ny) {
    x = nx;
    y = ny;
  }
}

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

/*
* IMPORTANT: This is the way the data is sent
*  'S' signals the beginning of transmission
*  'A' signals a pen raise
*  'Z' signals a pen lower
*  numbers are sent multiplied by 10000 and truncated to int 
*  numbers are sent as strings, one character at a time
*  '.' signals the end of a number
*  'T' signals the end of the transmission
*/
void sendData() {
  // first rescale and translate the data
  // find max and min data
  double minx = 1e10;
  double maxx = -1e10;
  double miny = 1e10;
  double maxy = -1e10;
  double x, y, scl;
  for (int i=0; i<allpoints.size(); i++) {
    x = allpoints.get(i).x;
    y = allpoints.get(i).y;
    if(x > maxx){ maxx = x; }
    if(x < minx){ minx = x; }
    if(y > maxy){ maxy = y; }
    if(y < miny){ miny = y; }
  }
  if(maxy-miny > maxx-minx){
    scl = maxdim/(maxy-miny);
  }else{
    scl = maxdim/(maxx-minx);
  }
  for (int i=0; i<allpoints.size(); i++) {
    allpoints.get(i).x = scl*(allpoints.get(i).x - minx);
    allpoints.get(i).y = scl*(allpoints.get(i).y - miny);
  }
  
  // Then send the data 
  int timeLimit = 0;
  int confirm = 8;
  int check = 0;
  String xdat, ydat;
  // clear the port
  println(sPort.available());
  while (sPort.available () > 0) {
    sPort.read();
    
  }
  println(sPort.available());
  
  // signal to begin 
  sPort.write('S');
  println("serial port write 'S' ");
 delay(150);
  println(sPort.available());
  while (sPort.available () > 0)
  {
    delay(1);
    timeLimit++;
    if (timeLimit >30000)
    {
      println("time out");
      return;
    }
  }
  
 
  sPort.write('0');
      println("xdat at: first = 0");
      delay(150);
  sPort.write('.');
    delay(150);
    println("serial port write '.' ");
    
    sPort.write('0');
      println("ydat at: first = 0");
      delay(150);
    
    sPort.write('.');
    delay(150);
    println("serial port write '.' ");
    
    
  
  
  // send each point
  for(int i=0; i<allpoints.size(); i++){
    sPort.read();
          delay(150);
    // if there is a z change, do that first
    for(int j=0; j<zchanges.size(); j++){
      sPort.read();
          delay(150);
      if ((zchanges.get(j) == i || zchanges.get(j) == -i) && i > 0) {
        if (zchanges.get(j) == i) {
          sPort.read();
          delay(150);
          sPort.write('A'); // this moves the pen up
          println("serial port write 'A' ");
          delay(150);
          
        }
        else {
          sPort.read();
          delay(150);
          sPort.write('Z'); // this moves the pen down
          println("serial port write 'Z' ");
          delay(150);
         
        }
        timeLimit = 0;
        
        //check = sPort.read();
        zdown = !zdown;
        println("switched Z: "+zdown);
        break;
      }
    }
    // send a string of x data, wait for reply
    xdat = String.valueOf((int)(allpoints.get(i).x*10000));
    for (int j=0; j<xdat.length(); j++) {
      
      sPort.write(xdat.charAt(j));
      println("xdat at: "+j+" = "+xdat.charAt(j));
      delay(150);
      
    }
    sPort.write('.');
    println("serial port write '.' ");
    delay(150);
    
    
    timeLimit = 0;
   
    check = sPort.read();
    while (sPort.available () > 0) {
      sPort.read();
    }
    println(sPort.available());
    // send a string of y data, wait for reply
    ydat = String.valueOf((int)(allpoints.get(i).y*10000));
    for (int j=0; j<ydat.length(); j++) {
      
      sPort.write(ydat.charAt(j));
      println("ydat at: "+j+" = "+ydat.charAt(j));
      delay(150);
      
    }
    
    sPort.write('.');
    delay(150);
    println("serial port write '.' ");
    timeLimit = 0;
    
    check = sPort.read();
    while (check != 'D')
    {check = sPort.read();
     timeLimit++;
     delay(1);
  if (timeLimit>30000)return;
}
    while (sPort.available () > 0) {
      sPort.read();
    }

    println("sent N:"+i+" X:"+String.valueOf(allpoints.get(i).x)+" Y:"+String.valueOf(allpoints.get(i).y));
  }
  // now we have sent all of the data. Yay!
  // signal to end 
  sPort.read();
  delay(150);
  sPort.write('T');
  println("serial port write 'T' ");
  delay(150);
  
  
}

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

/*
* This draws a picture from the list of coordinates
*/
void makePicture() {
  int x0 = 50;
  int y0 = 50;
  int xn = 0;
  int yn = 0;
  float scl = 1.0; // pixels per mm
  float tmpx = 0.0;
  float tmpy = 0.0;
  int sign = 1;
  zdown = true;
  // find max and min data
  double minx = 1e10;
  double maxx = -1e10;
  double miny = 1e10;
  double maxy = -1e10;
  double x, y;
  for (int i=0; i<allpoints.size(); i++) {
    x = allpoints.get(i).x;
    y = allpoints.get(i).y;
    if(x > maxx){ maxx = x; }
    if(x < minx){ minx = x; }
    if(y > maxy){ maxy = y; }
    if(y < miny){ miny = y; }
  }
  if(maxy-miny > maxx-minx){
    scl = (float)(width*1.0/(maxy-miny));
  }else{
    scl = (float)(width*1.0/(maxx-minx));
  }
  
  x0 = (int)(minx*scl);
  y0 = (int)(miny*scl);
  
  for (int i=0; i<allpoints.size(); i++) {
    for (int j=0; j<zchanges.size(); j++) {
      if (zchanges.get(j) == i) {
        zdown = false;
      }
      if (zchanges.get(j) == -i && i > 0) {
        zdown = true;
      }
    }
    tmpx = (float)allpoints.get(i).x;
    tmpy = (float)allpoints.get(i).y;
    if (zdown) {
      line(xn-x0, (yn-y0), int(tmpx*scl)-x0, (int(tmpy*scl)-y0));
    }
    xn = int(tmpx*scl);
    yn = int(tmpy*scl);
  }
}

void draw() {
  // write it serially to the usb port to be read by the arduino
  if(sendIt){
    sendData();
  }
  // draw a picture of what it should look like on the screen
  makePicture();
  
  noLoop(); // only do it once
}

