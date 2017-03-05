// Processing.
// JS ported from Java. 
//

// No of cells between the centre and edge DIAGONALLY
// It's kind of confusing, but it makes sense in the code
// Works nicely between 4 to 6
var triangleRadius = 8;
var triangleDiameter = (triangleRadius*4) - 1;

// This specifies how much the shape should resemble a 'star'
//   == 1 makes a cross
//   == 2 makes a square diamond
//   >= 2 makes a star
var starness = 2.7;

// Cell will be drawn if the RNG is below 1
// So a value of 3 will draw about 1/3 of the cells
var randomUpperLimit = 1.8;

// The dimensions of each cell
var cellW = 7;
var cellH = cellW;

// The ideal pixel size for the canvas
var yPixelIdeal = 256;
var xPixelIdeal = yPixelIdeal * 1;
//var xPixelIdeal = yPixelIdeal * 0.9;
//var xPixelIdeal = yPixelIdeal * 1.8;

// Has to be an odd number to make sure we have a central pixel
var xCells = (xPixelIdeal / cellW) + 1;
var yCells = (yPixelIdeal / cellH) + 1;

// Find central cell
var centreCellX = (xCells - 1) / 2;
var centreCellY = (yCells - 1) / 2;

// Pallete for the cell colours
var colourType = 8;


function setup() {
  var crossCanvas = createCanvas(xCells*cellW,yCells*cellH);
  crossCanvas.parent('noisy_cross');
  
  background(0);
  frameRate(8);
}

function draw() {
  background(0);
  
  // Draw five crosses, with the centres in an X
  // (like the pips of a 5 on a die)  
  newPattern(triangleRadius*2          , triangleRadius*2);
  newPattern(triangleRadius*2          , yCells-1-triangleRadius*2);
  newPattern(xCells-1-triangleRadius*2 , triangleRadius*2);
  newPattern(xCells-1-triangleRadius*2 , yCells-1-triangleRadius*2);
  newPattern(centreCellX, centreCellY);
  
  
  /*
  // Let's just keep it green for now.
  
  if (mouseIsPressed) {
    colourType++;
    if (colourType > 12) {
      colourType = 0;
    }
  }
  */
  
}


function newPattern(centreCellX, centreCellY) {
  centreCellX = Math.floor(centreCellX);
  centreCellY = Math.floor(centreCellY);

  for(i=0; i<triangleRadius; i++){
    for(j=0; j<( (triangleRadius*2) - (starness*i) ); j++){
      
      //// Colours /////////////////////////////////
      switch(colourType) {
      
        // White
        case 0:
          fill(255);
          break;
          
        // Grey
        case 1:
          fill(255-i*60, 255-i*60, 255-i*60);
          break;
          
        // Dark red
        case 2:
          fill(210-(150/triangleRadius)*i, 20, 0);
          break;
          
        // Cross red (makes a more pronounced 'cross' effect)
        case 3:
          fill(220-(220/triangleRadius)*i, 0, 0);
          break;
          
        // Red cross
        case 4:
          fill(255-i*60, 0, 0);
          break;
          
        // Dark blue
        case 5:
          fill(0, 0, 255-(255/triangleRadius)*i );
          break;
          
        // Lighter blue
        case 6:
          fill(0, 0, random(100,255));
          break;
          
        // Blue cross
        case 7:
          fill(0, 0, 255-i*60);
          break;
          
        // Green cross
        case 8:
          fill(0, 255-i*60, 0);
          break;
          
        // Yellow cross
        case 9:
          fill(255-i*60, 255-i*60, 0);
          break;
          
        // Completely random (stained glass window / rag rug effect)
        // (Warning: kinda lame)
        case 10:
          fill(random(255), random(255), random(255));
          break;
        case 11:
          fill(random(255), random(255), random(255), 110+(100/triangleRadius)*i);
          break;
        case 12:
          fill(random(255)-i*60, random(255)-i*60, random(255)-i*60);
          break;
          
        default:
      }
      //////////////////////////////////////////////
      
      // Split the square into eighths, and have each square in each eighth behave the same
      var rand = Math.floor(Math.random() * randomUpperLimit);
      if (rand<1) {
        rect( (centreCellX+i)*cellW, (centreCellY+j+i)*cellH, cellW, cellH);
        rect( (centreCellX-i)*cellW, (centreCellY+j+i)*cellH, cellW, cellH);
        rect( (centreCellX+i)*cellW, (centreCellY-j-i)*cellH, cellW, cellH);
        rect( (centreCellX-i)*cellW, (centreCellY-j-i)*cellH, cellW, cellH);
        rect( (centreCellX+j+i)*cellW, (centreCellY+i)*cellH, cellW, cellH);
        rect( (centreCellX-j-i)*cellW, (centreCellY+i)*cellH, cellW, cellH);
        rect( (centreCellX+j+i)*cellW, (centreCellY-i)*cellH, cellW, cellH);
        rect( (centreCellX-j-i)*cellW, (centreCellY-i)*cellH, cellW, cellH);
      }
    }
  }
}
