//////////////////////////////////////////////////////////////////////
// JavaScript ported from Processing (Java)
//////////////////////////////////////////////////////////////////////
var randomLimits = 8;
//////////////////////////////////////////////////////////////////////
function setup() {
  var tildeCanvas = createCanvas(300,300);
  tildeCanvas.parent('tilde_circle');
  
  frameRate(14);
  background(0);
  
  textFont("Courier New");
  textAlign(CENTER);
  stroke(255);
  strokeWeight(1);
  fill(0);
  noFill();

  draw();
}
//////////////////////////////////////////////////////////////////////
function draw() {
  background(0);
  
  noFill();
  for (var i=0; i<50; i++) {
    var rCol = random(-5,5);
    stroke( 0,random(230+rCol),0 );
    var r1 = random(-randomLimits,randomLimits);
    var r2 = random(-randomLimits,randomLimits);
    var r3 = random(-randomLimits,randomLimits);
    var r4 = random(-randomLimits,randomLimits);
    ellipse(150+r1, 150+r2, 250+r3, 250+r4);
  }
  
  var yCount = 0;
  for (var iFontSize = 200; iFontSize >= 124; iFontSize-=10) {
      var rCol = random(-5,5);
      fill( 0,random(230+rCol),0 );
      
      textSize(iFontSize);
      text("~", 150+random(-1,1), 210+rCol+yCount );
      yCount-=2.9;
  }
}
//////////////////////////////////////////////////////////////////////
