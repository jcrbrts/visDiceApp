import controlP5.*;

ControlP5 cp5;

/* Program: visDiceApp.

   Application to run the VisDice design method of design thinking.
   The program runs in the Processing.org environment.
   Load the program .pde into Processing.org, and make sure the image files are set
   in the Processing folder under the same name.
   
   The program loads images from file and allows people to select and "roll" the images
   Images can be rolled one by one, or all together. 
   Images can be shown (on) or hidden (off).
   Copyright (C) 2025, Jonathan C. Roberts,  
    
   This program is free software: you can redistribute it and/or modify
   it under the terms of the CC BY-NC 4.0
   Attribution-NonCommercial 4.0 International
   
   This is version 4.0, which moves the original application to ControlP5
   It was designed for Processing 4.3.2
   It was designed to run with ControlP5 2.2.6
   */


PImage[][] diceImages = new PImage[6][6];
boolean[] diceVisible = new boolean[6];
int[] currentImageIndex = new int[6];
boolean[] isFlickering = new boolean[6];
int[] flickerStartTime = new int[6];
float flickerDuration = 2.0;
char[] diceNames = {'D', 'E', 'P', 'V', 'A', 'I'};
String[] diceLabels = {"Design", "Environment", "Proxemics", "Display", "Art", "Interaction"};
String flickerDurationInput = "2.0";
boolean allDiceVisible = false;
boolean showDiceNames = true;

int screenWidth = 1000; // Initial screen width
int screenHeight = 900; // Initial screen height



void setup() {
  windowTitle("VisDiceApp");
  size(1000, 900);
  surface.setResizable(true);
  surface.setLocation(100, 100);
  registerMethod("pre", this);
  refreshPG();

  cp5 = new ControlP5(this);

  // Create dice control buttons for each of the six dice
  for (int i = 0; i < 6; i++) {
    int x, y;
    if (i < 3) {
      // top row dice buttons
      x = 100 + i * 300;
      y = 270;
    } else {
      // bottom row dice buttons
      x = 100 + (i - 3) * 300;
      y = 620;
    }
    // Add Roll button (momentary button)
    cp5.addButton("rollDice" + i)
      .setPosition(x, y)
      .setSize(100, 30)
      .setLabel("Roll");

    // Add Show/Hide toggle (switch style)
    cp5.addToggle("toggleDice" + i)
      .setPosition(x + 110, y)
      .setSize(80, 30)
      .setValue(false)
      .setMode(ControlP5.SWITCH)
      .setLabel("Display");
  }
  
  // Create flicker duration textfield
  cp5.addTextfield("flickerDurationInput")
    .setPosition(100, 800)
    .setSize(100, 30)
    .setText("2.0")
    .setAutoClear(false)
    .setLabel("Duration");

  // Create On/Off toggle for all dice visibility
  cp5.addToggle("allDiceVisible")
    .setPosition(220, 800)
    .setSize(100, 30)
    .setValue(false)
    .setMode(ControlP5.SWITCH)
    .setLabel("Show all");

  // Create Roll All button
  cp5.addButton("rollAllDice")
    .setPosition(340, 800)
    .setSize(100, 30)
    .setLabel("Roll All");

  // Create Show Names toggle
  cp5.addToggle("showDiceNames")
    .setPosition(460, 800)
    .setSize(120, 30)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    .setLabel("Show Names");
   
  // Apply cexamplustom styling to each ControlP5 element
  for (int i = 0; i < 6; i++) {
    // Style the Roll buttons
    Button rollButton = cp5.get(Button.class, "rollDice" + i);
    rollButton.setColorBackground(color(150, 150, 250));  // Idle background
    rollButton.setColorForeground(color(200, 200, 255));  // Hover color
    rollButton.getCaptionLabel().setFont(createFont("Arial", 14));
    rollButton.getCaptionLabel().setColor(color(255));
    rollButton.getCaptionLabel().toUpperCase(false);
    

    // Style the Show/Hide toggles
    Toggle toggleButton = cp5.get(Toggle.class, "toggleDice" + i);
    toggleButton.setMode(ControlP5.SWITCH);
    toggleButton.setColorActive(color(200, 200, 200));
    toggleButton.setColorBackground(color(150, 150, 250));
    toggleButton.setColorForeground(color(150, 150, 250));//color(150, 150, 250));  // Foreground when off
    toggleButton.getCaptionLabel().setFont(createFont("Arial", 14));
    toggleButton.getCaptionLabel().setColor(color(0));
    toggleButton.getCaptionLabel().toUpperCase(false);
  }

  // Style the bottom controls

  // Flicker Duration Textfield
  Textfield tf = cp5.get(Textfield.class, "flickerDurationInput");
  tf.getCaptionLabel().setFont(createFont("Arial", 14));
  tf.getCaptionLabel().setColor(color(0));
  tf.setColor(color(255));
  tf.setColorBackground(color(200));
  tf.getCaptionLabel().toUpperCase(false);

  // All Dice Visibility Toggle
  Toggle allDiceToggle = cp5.get(Toggle.class, "allDiceVisible");
  allDiceToggle.setColorForeground(color(150, 150, 250));
  allDiceToggle.setColorActive(color(200, 200, 200));
  allDiceToggle.setColorBackground(color(150, 150, 250));
  allDiceToggle.getCaptionLabel().setFont(createFont("Arial", 14));
  allDiceToggle.getCaptionLabel().setColor(color(0));
  allDiceToggle.getCaptionLabel().toUpperCase(false);

  // Roll All Button
  Button rollAllButton = cp5.get(Button.class, "rollAllDice");
  rollAllButton.setColorBackground(color(150, 150, 250));
  rollAllButton.setColorForeground(color(150, 150, 250));
  rollAllButton.setColorActive(color(200, 200, 200));
  rollAllButton.getCaptionLabel().setFont(createFont("Arial", 14));
  rollAllButton.getCaptionLabel().setColor(color(0));

  // Show Names Toggle
  Toggle showNamesToggle = cp5.get(Toggle.class, "showDiceNames");
  showNamesToggle.setColorForeground(color(150, 150, 250));
  showNamesToggle.setColorBackground(color(150, 150, 250));
  showNamesToggle.setColorActive(color(200, 200, 200));
  showNamesToggle.getCaptionLabel().setFont(createFont("Arial", 14));
  showNamesToggle.getCaptionLabel().setColor(color(0));
  showNamesToggle.getCaptionLabel().toUpperCase(false);

  // Load dice images and initialize arrays
  for (int d = 0; d < 6; d++) {
    for (int i = 0; i < 6; i++) {
      String imageName = String.format("dice-%c-%02d.jpg", diceNames[d], i + 1);
      diceImages[d][i] = loadImage(imageName);
    }
    diceVisible[d] = false;
    currentImageIndex[d] = 0;
    isFlickering[d] = false;
  }

  textSize(16);
}

void draw() {
  background(255);
  // Draw top row of dice
  for (int i = 0; i < 3; i++) {
    drawDice(i, 100 + i * 300, 50);
  }
  // Draw bottom row of dice
  for (int i = 3; i < 6; i++) {
    drawDice(i, 100 + (i - 3) * 300, 400);
  }
  updateFlickering();
}

void drawDice(int index, int x, int y) {
  if (showDiceNames) {
    fill(0);
    textAlign(CENTER);
    text(diceLabels[index], x + 100, y - 10);
  }
  if (diceVisible[index]) {
    image(diceImages[index][currentImageIndex[index]], x, y, 200, 200);
    fill(0);
    textAlign(CENTER);
    text(diceNames[index] + String.valueOf(currentImageIndex[index] + 1), x + - 10, y + - 10);
  } else {
    fill(255);
    rect(x, y, 200, 200);
  }
}

void startFlicker(int index) {
  isFlickering[index] = true;
  flickerStartTime[index] = millis();
}

void updateFlickering() {
  for (int i = 0; i < 6; i++) {
    if (isFlickering[i]) {
      int elapsedTime = millis() - flickerStartTime[i];
      int flickerSteps = int(flickerDuration * 10);
      if (elapsedTime < flickerDuration * 1000) {
        if (elapsedTime % (1000 / flickerSteps) < (1000 / flickerSteps) / 2) {
          currentImageIndex[i] = int(random(6));
        }
      } else {
        isFlickering[i] = false;
      }
    }
  }
}

// Callback functions for the individual Roll buttons
public void rollDice0() {
  startFlicker(0);
}
public void rollDice1() {
  startFlicker(1);
}
public void rollDice2() {
  startFlicker(2);
}
public void rollDice3() {
  startFlicker(3);
}
public void rollDice4() {
  startFlicker(4);
}
public void rollDice5() {
  startFlicker(5);
}

// Callback functions for the individual Show/Hide toggles
public void toggleDice0(float val) {
  diceVisible[0] = (val > 0.5);
}
public void toggleDice1(float val) {
  diceVisible[1] = (val > 0.5);
}
public void toggleDice2(float val) {
  diceVisible[2] = (val > 0.5);
}
public void toggleDice3(float val) {
  diceVisible[3] = (val > 0.5);
}
public void toggleDice4(float val) {
  diceVisible[4] = (val > 0.5);
}
public void toggleDice5(float val) {
  diceVisible[5] = (val > 0.5);
}

// Callback for the Roll All button
public void rollAllDice() {
  for (int i = 0; i < 6; i++) {
    diceVisible[i] = true;
    startFlicker(i);
  }
}

// Callback for the All Dice toggle
public void allDiceVisible(float val) {
  allDiceVisible = (val > 0.5);
  for (int i = 0; i < 6; i++) {
    diceVisible[i] = allDiceVisible;
  }
}

// Callback for the Show Names toggle
public void showDiceNames(float val) {
  showDiceNames = (val > 0.5);
}

// Callback for the flicker duration textfield
public void flickerDurationInput(String theText) {
  flickerDurationInput = theText;
  try {
    flickerDuration = Float.parseFloat(theText);
    //println("Updated flicker duration: " + flickerDuration);

  }
  catch(Exception e) {
    // Ignore invalid input
  }
}

int w, h;
String ws = "";
PGraphics pg;

void pre() {
  if (w != width || h != height) {
    // Sketch window has resized
    w = width;
    h = height;
    ws = "Size = " + w + " x " + h + " pixels";
    refreshPG();
  }
}

void refreshPG() {
  int ww = int(w / 3.0);
  int hh = int(h / 3.0);
}
