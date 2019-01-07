import java.util.*;

Player player;
PImage path;
boolean tuioUpdated = false;

HashMap<Integer, Block> blocks = new HashMap<Integer, Block>();
Actions actions;
TuioProcessing tuioClient;

PlayPauseButton playPauseButton;
ResetButton resetButton;

void setup() {
  textAlign(CENTER, CENTER);
  size(800, 663);
  smooth();
  frameRate(60);
  path = loadImage("path.png");
  player = new Player(new PVector(5, 5));

  actions = new Actions();
  tuioClient = new TuioProcessing(this);
  playPauseButton = new PlayPauseButton(new PVector(width-125, height-75), 50);
  resetButton = new ResetButton(new PVector(width-50, height-75), 50);
  background(50);
}

void draw() {
  List<Block> currentBlocks = new LinkedList<Block>(blocks.values());
  if (tuioUpdated) {
    background(50);

    updateCodeTrain(new LinkedList(currentBlocks));
    tuioUpdated = false;
    actions.update(codeTrain);
  }

  if (playPauseButton.getPlaying()) {
    try {
      actions.execute();
    } 
    catch (IOException e) {
      noLoop();
      println("[ERROR] Pointed at an invalid block");
      println("[ERROR] Pointer at: ", actions.pointer.pointer);
    }
  }
  drawBackground();
  for (Block b : currentBlocks) {
    b.drawBlock();
  }
  drawCodeTrain(codeTrain);
  actions.printActions(width - 150, 25);
  player.collide(path);
  player.draw();
  drawButtons();

  for (Cursor c: cursors.values()) {
    c.draw();
  }
}

void drawButtons() {
  playPauseButton.draw();
  resetButton.draw();
}

void drawBackground() {
  background(255);
  noStroke();
  fill(230);
  rect(0, 642, width, 21);
  fill(0, 255, 0);
  rect(308, 642, 42, 21);
  image(path, 0, 0);
}

List<Block> codeTrain = new LinkedList<Block>();

/**
 * Tries to get the starting element from the list of elements, if it exists, start the train, otherwise return an empty list.
 */
void updateCodeTrain(List<Block> elements) {
  Optional<Block> firstElement = getStartingElement(elements);

  if (firstElement.isPresent()) {
    List<Block> train = new LinkedList<Block>();
    train.add(firstElement.get());
    elements.remove(firstElement.get());
    codeTrain = train(elements, train);
  } else {
    codeTrain = new LinkedList();
  }
  //println(codeTrain);
}

/**
 * Starts a train for the train function, takes the '0' element from the list of elements and returns the completed train.
 */
List<Block> generateTrain(Block firstElement, List<Block> elements) {
  List<Block> train = new LinkedList<Block>();
  train.add(firstElement);
  elements.remove(firstElement);
  return train(elements, train);
}

/**
 * Recursive function, recieves a list of elements and a train of elements if an element is close to the end of the train, it is added to the train and the function is run again, otherwise the existing train is returned.
 */
List<Block> train(List<Block> elements, List<Block> train) {
  Block end = train.get(train.size() - 1);
  for (Block e : elements) {
    float dist = dist(end.position.x, end.position.y, e.position.x, e.position.y);
    float angle = atan2(e.position.y - end.position.y, e.position.x - end.position.x) + (PI*1.5);
    if (e instanceof Query && end instanceof If && anglesClose(angle - (TWO_PI * 0.75), end.rotation, e.rotation, 0.5) && dist < end.size + e.size) {
      If ifEnd = (If) end;
      ifEnd.setQuery((Query) e);
      elements.remove(e);
      return train(elements, train);
    } else if (end instanceof Iterable && dist < end.size + e.size) {
      if (anglesClose(angle - (TWO_PI * 0.875), end.rotation, e.rotation, 0.5)) {
        train.add(e);
        elements.remove(e);
        return train(elements, train);
      }
    } else if (e instanceof OutDent && dist < end.size + e.size) {
      if (anglesClose((angle + (TWO_PI * 0.875)) % TWO_PI, end.rotation, e.rotation, 0.5)) {
        train.add(e);
        elements.remove(e);
        return train(elements, train);
      }
    } else if (dist < end.size + e.size) {
      if (anglesClose(angle, end.rotation, e.rotation, 0.5)) {
        train.add(e);
        elements.remove(e);
        return train(elements, train);
      }
    }
  }
  return train;
}

boolean incrementAngleClose(float angle, float objA, float objB, float give) {
  return angleClose(objA, objB, give) && angleClose(angle, objA, give);
}

boolean anglesClose(float angle, float objA, float objB, float give) {
  return angleClose(angle, objA, give) && angleClose(objA, objB, give);
}

/**
 * Recieves 2 angles and an amount of give and tests if the difference between them is less than the given give, ensuring the calculation wraps over.
 */
boolean angleClose(float angleA, float angleB, float give) {
  return abs(angleA-angleB) < give || abs((angleA-TWO_PI)-angleB) < give || abs(angleA-(angleB-TWO_PI)) < give;
}

/**
 * Receives a collection of elements, if the collection contains an element with the fedId '0' then it is returned as an observable, otherwise an empty observable is returned.
 */
Optional<Block> getStartingElement(Collection<Block> elements) {
  for (Block e : elements) {
    if (e.fedId == 0 && e.visible) {
      return Optional.of(e);
    }
  }
  return Optional.empty();
}

void drawCodeTrain(List<Block> train) {
  strokeWeight(3);
  stroke(0);
  for (int i=0; i<train.size() - 1; i++) {
    Block a = train.get(i);
    Block b = train.get(i + 1);
    line(a.position.x, a.position.y, b.position.x, b.position.y);
  }
}

void keyPressed() {
  if (key == ' ') {
    playPauseButton.pressed();
  }
}

void mousePressed() {
  PVector mousePos = new PVector(mouseX, mouseY);
  if (playPauseButton.inButton(mousePos)) {
    playPauseButton.pressed();
  }
  if (resetButton.inButton(mousePos)) {
    resetButton.pressed();
  }
}
