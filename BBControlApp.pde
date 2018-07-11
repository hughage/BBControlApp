
import oscP5.*;
import netP5.*;

int[][] colours = new int[4][3];
int[] yellow = { 125, 255, 176 };
int[] blue = { 204, 236, 207 };
int[] green = { 207, 236, 207 };
int[] purple = { 221, 212, 232 };
float[] bc = { 0f, 0f, 0f }; // current background coulour
int steps = 100;
int stepCount = 0;
int previousColour = 0;
int nextColour = 1;
float[] difSteps ={0, 0, 0};
int count = 0;

OscP5 oscP5;
NetAddress myRemoteLocation;

int lineCount =0;
float py = 0f;
float y = 0f;

boolean valveOn = false;
boolean pumpOn = false;

boolean trueValveState;
boolean truePumpState;
float pressureValue =0.5;

String OSCip = "Please press ping button on x-osc";

void setup() {
  fullScreen();
  intializeColours();
  refreshGraph();
  // listen on my local ip at 1200 port
  oscP5 = new OscP5(this, 8000); //9000
  //Desktop ip address
  myRemoteLocation = new NetAddress("192.168.43.120", 8000);
  getXoscData();
}

void draw() {
   
  calcColour();
  fill(bc[0], bc[1], bc[2]);
  noStroke();
  rect(0,0,width,4*(height/5));
  textAlign(CENTER, CENTER);
  textSize(40);
  fill(255-bc[0], 255-bc[1], 255-bc[2]);
  text("hello there\n\n"+OSCip+"\nreported xosc pressure value\n"+pressureValue, width/2, 3*(height/5));
  drawButton();
  drawGraph();
}

public void drawGraph() {
  lineCount++; 
  if (lineCount>width) {
    refreshGraph();
  }
  py=y;
  y = map(pressureValue,0,1,height, height-(height/5));
  stroke(0);
  line(lineCount-1, py,lineCount, y);
  noStroke();
}

public void refreshGraph() {
  lineCount =0;
  fill(255);
  noStroke();
  rect(0, height-(height/5), width, height/5);
}


public void drawButton() {
  noStroke();
  if (pumpOn) {
    fill(0, 0, 255);
    rect(10, 10, width-20, (height/5)-10,10);
    fill(255);
    text("pump is on", width/2, height/10);
  } else {
    fill(0, 255, 0);
    rect(10, 10, width-20, (height/5)-10,10);
    fill(0);
    text("pump is off", width/2, (height/10));
  }

  if (valveOn) {
    fill(0, 0, 255);
    rect(10, (height/5)+10, width-20, (height/5)-20,10);
    fill(255);
    text("valve is on", width/2, (height/5)+(height/10));
  } else {
    fill(0, 255, 0);
    rect(10, (height/5)+10, width-20, (height/5)-10,10);
    fill(0);
    text("valve is off", width/2, (height/5)+(height/10));
  }
}

public void intializeColours() {
  colours[0] = yellow;
  colours[1] = blue;
  colours[2] = green;
  colours[3] = purple;
  bc[0]=(float)colours[previousColour][0];
  bc[1]=(float)colours[previousColour][1];
  bc[2]=(float)colours[previousColour][2];
  difSteps[0] = (float) (colours[nextColour][0] - colours[previousColour][0]) / (float) steps;
  difSteps[1] = (float) (colours[nextColour][1] - colours[previousColour][1]) / (float) steps;
  difSteps[2] = (float) (colours[nextColour][2] - colours[previousColour][2]) / (float) steps;
}

public void calcColour() {
  stepCount++;
  if (stepCount == steps) {
    stepCount = 0;
    previousColour = nextColour;
    if (nextColour < colours.length - 1) {
      nextColour++;
    } else {
      nextColour = 0;
    }
    difSteps[0] = (float) (colours[nextColour][0] - colours[previousColour][0]) / (float) steps;
    difSteps[1] = (float) (colours[nextColour][1] - colours[previousColour][1]) / (float) steps;
    difSteps[2] = (float) (colours[nextColour][2] - colours[previousColour][2]) / (float) steps;
  }
  bc[0] = bc[0] + difSteps[0];
  bc[1] = bc[1] + difSteps[0];
  bc[2] = bc[2] + difSteps[0];
}

void mousePressed() {

  if (mouseY>0 && mouseY<height/5) {
    pumpOn= !pumpOn;
    println("Pump on is: "+pumpOn);
  }

  if (mouseY>height/5 && mouseY<2*height/5) {
    valveOn= !valveOn;
    println("Valve on is: "+valveOn);
  }

  if (pumpOn) {
    OscMessage myMessage = new OscMessage("/outputs/digital/1");
    myMessage.add(1);
    oscP5.send(myMessage, myRemoteLocation);
    println("sent pump on");
  } else {
    OscMessage myMessage = new OscMessage("/outputs/digital/1");
    myMessage.add(0);
    oscP5.send(myMessage, myRemoteLocation);
    println("sent pump off");
  }

  if (valveOn) {
    OscMessage myMessage = new OscMessage("/outputs/digital/2");
    myMessage.add(1);
    oscP5.send(myMessage, myRemoteLocation);
    println("sent valve on");
    getXoscData();
  } else {
    OscMessage myMessage = new OscMessage("/outputs/digital/2");
    myMessage.add(0);
    oscP5.send(myMessage, myRemoteLocation);
    println("sent valve off");
    getXoscData();
  }
  count++;
}

public void getXoscData(){
    println("Get data message");
    OscMessage newMessage = new OscMessage("/inputs/analogue/read");
    oscP5.send(newMessage, myRemoteLocation);
}

void oscEvent(OscMessage theOscMessage) {   
  if (theOscMessage.checkAddrPattern("/inputs/analogue")==true) {
      pressureValue= theOscMessage.get(0).floatValue();  
      println(pressureValue);
    }
  if (theOscMessage.checkAddrPattern("/ping")==true) {
    if (theOscMessage.checkTypetag("sss")) {
      println(theOscMessage.get(0).stringValue());
      println(theOscMessage.get(1).stringValue());
      println(theOscMessage.get(2).stringValue());
      OSCip = "x-osc ip: "+theOscMessage.get(0).stringValue();
    }
  }
}
