////////////////////////////////////////////////////////////////////////////////
// JavaScript ported from Processing (Java)
//
// I'm not happy with this. I shouldn't use processing to animate text, but I'm
// still learning JS at the moment. And there shouldn't be blank borders around
// each letter. It looks better in the Java environment, I swear.
////////////////////////////////////////////////////////////////////////////////

// Speed and life of objects.
var speed = 18;
var maxLife = 100;

// This can be altered to adjust the size of the characters and screen.
var fontSize = 40;
var dimXinit = 500;
var dimYinit = 300;

// Box drawing chars.
// http://jrgraphix.net/r/Unicode/2500-257F
var charsToOutput = [
  unescape(JSON.parse('"\\u2551"')),
  unescape(JSON.parse('"\\u2550"')),
  unescape(JSON.parse('"\\u255A"')),
  unescape(JSON.parse('"\\u2554"')),
  unescape(JSON.parse('"\\u2557"')),
  unescape(JSON.parse('"\\u255D"')),
  unescape(JSON.parse('"\\u2560"')),
  unescape(JSON.parse('"\\u2566"')),
  unescape(JSON.parse('"\\u2563"')),
  unescape(JSON.parse('"\\u2569"')),
  unescape(JSON.parse('"\\u256C"'))
];

// Globals.
var cells = [];
var xCharPix, yCharPix;
var xCharCount, yCharCount;

////////////////////////////////////////////////////////////////////////////////

function setup() {
  frameRate(speed);
  
  // A couple of magic numbers here, 1.66 and 0.88
  // These are the ratio of font size to pixel dimension in Courier New
  // So I guess if you don't have Courier New, it'll look horrible...
  xCharPix = Math.ceil(fontSize / 1.66);
  yCharPix = Math.ceil(fontSize / 0.88);
  println("xCharPix:" + xCharPix + " yCharPix:" + yCharPix);
  
  // How many characters per each axis.
  xCharCount = Math.ceil(dimXinit / xCharPix);
  yCharCount = Math.ceil(dimYinit / yCharPix);
  println("xCharCount:" + xCharCount + " yCharCount:" + yCharCount);
  
  // Resize the canvas area to fit the character "cells" exactly.
  dimX = xCharPix * xCharCount + 1;
  dimY = yCharPix * yCharCount + 1;
  println("dimX:" + dimX + " dimY:" + dimY);
  
  // Set up the font.
  textAlign(LEFT);
  textFont("Courier New");
  textSize(fontSize);

  // Create the canvas.
  var matrixCanvas = createCanvas(dimX,dimY);
  matrixCanvas.parent('matrix');
  background(0);
  
  // Create a new object for each cell.
  for ( var xCell = 0; xCell < xCharCount; xCell++ ) {
    for ( var yCell = 0; yCell < yCharCount; yCell++ ) {
      var newCell = new CharacterCell(xCell,yCell);
      cells.push(newCell);
    }
  }
  draw();
}

////////////////////////////////////////////////////////////////////////////////

function draw() {
  for ( var i = 0; i < cells.length; i++ ) {
    cells[i].display(); 
  }
}

////////////////////////////////////////////////////////////////////////////////

// This is dodgy. There's an extra column of chars to the right...
// Oh well. They're not visible but that's okay.
function CharacterCell(xCell,yCell) {
  this.xCell = xCell;
  this.yCell = yCell;
  this.xPixel = xCell * xCharPix;
  this.yPixel = (yCell+1) * yCharPix - yCharPix/3;
  this.charSymbol = charsToOutput[Math.floor(random(charsToOutput.length))];
  this.lifeLeft = Math.floor((random(maxLife)*0.8));
  
  this.display = function() {
    this.lifeLeft = this.lifeLeft - 1;
    
    var greenVal = ( this.lifeLeft*(255/maxLife) );
    fill( color(0,greenVal,0) );
    
    text(this.charSymbol, this.xPixel, this.yPixel);
    
    // When the time runs out, the character and brightness will be reset.
    if (this.lifeLeft <= 0) {
      this.lifeLeft = Math.floor(random(maxLife/5,maxLife));
      this.charSymbol = charsToOutput[Math.floor(random(charsToOutput.length))];
    }
  }
}

////////////////////////////////////////////////////////////////////////////////

