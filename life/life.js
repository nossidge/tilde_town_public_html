

/*

Warning: Work in progress.
This code is terrible!
I will tidy up eventually.



scp index.html life.js nossidge@tilde.town:/home/nossidge/public_html/life/



LifeBloom
Width:	111
Height:	111
Pixels:	6
Blur:	0.01




Quick Maze
2x2
*/



//##############################################################################
// Helper functions.
//########################################

// Console log wrapper. Set to false when web page is live.
var writeToConsole = false;
function puts(input) {
  if (writeToConsole) {
    console.log(input);
  }
}

// Random number between two values.
function rand(max, min, _int) {
  var max = (max === 0 || max)?max:1, 
      min = min || 0, 
      gen = min + (max - min) * Math.random();
  return (_int) ? Math.round(gen) : gen;
}

// Alter CSS through JavaScript.
// http://stackoverflow.com/a/11081100/139299
function css(selector, prop, val) {
  for (var i=0; i<document.styleSheets.length; i++) {
    try {
      document.styleSheets[i].insertRule(selector+ ' {'+prop+':'+val+'}', document.styleSheets[i].cssRules.length);
    } catch(e) {
      try {
        document.styleSheets[i].addRule(selector, prop+':'+val);
      } catch(e) {}
    }
  }
}

// http://stackoverflow.com/a/5624139/139299
function hexToRgb(hex) {
  var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : null;
}

// Update a DOM element.
function updateDOMInnerHTML(DOMID, text) {
	document.getElementById(DOMID).innerHTML = text;
}
function updateDOMValue(DOMID, text) {
	document.getElementById(DOMID).value = text;
}

//##############################################################################

//set the variables
var a = document.getElementById('canvas');
var c = a.getContext('2d');
var ANIMATION;
var frameRate = 8;
var frameCount = 0;

var cellCount  = {x: 99, y: 99};
var cellPixels = {x: 8,  y: 8};
var centreCell = {x: 49, y: 49};

var blur = 1;

var fillColourDead  = '#000000';
var fillColourAlive = '#E0B0FF';

var currentRuleType = 'Conway';
var loopType = '(none)';
var paused = false;

var cells;

var loopState = 0;

var lastCustomRuleName = '(custom 1)';

var paused = false;
var epilepsySafe = true;


//##############################################################################

// Defined Rules and Loops.

lifeRules = {
  "Conway": {
    "description": "Classic.",
    "character": "Chaotic",
    "birth": [3],
    "survival": [2,3]
  },
  "HighLife": {
    "description": 'Similar to life, but "richer in nice things".',
    "character": "Chaotic",
    "birth": [3,6],
    "survival": [2,3]
  },
  "MazeOfficial": {
    "description": "Complex growing maze-like structures with well-defined walls outlining corridors.",
    "character": "Explosive",
    "birth": [3],
    "survival": [1,2,3,4,5]
  },
  "Mazectric": {
    "description": "Maze patterns that tend to have longer and straighter corridors.",
    "character": "Explosive",
    "birth": [3],
    "survival": [1,2,3,4]
  },
  "Flakes": {
    "description": "Life without death. Ever expanding immortality.",
    "character": "Explosive",
    "birth": [3],
    "survival": [0,1,2,3,4,5,6,7,8]
  },
  
  
  
  
  
  
  
  
  "34 Life": {
    "birth": [3,4],
    "survival": [3,4]
  },
  "Dry Life": {
    "birth": [3,7],
    "survival": [2,3]
  },
  "Coral": {
    "birth": [3],
    "survival": [4,5,6,7,8]
  },
  "Move": {
    "birth": [3,6,8],
    "survival": [2,4,5]
  },
  
  
  "Quick Maze": {
    "description": "Rapidly spreading, loop terminating.",
    "birth": [3],
    "survival": [1,2,3,4,5,8]
  },
  "Static Maze": {
    "description": "Terminating.",
    "birth": [3],
    "survival": [1,2,3,4,5,6]
  },
  "Static Maze 2": {
    "description": "",
    "birth": [0,2],
    "survival": [1,2,3,4,5]
  },
  
  
  "Vote": {
    "birth": [5,6,7,8],
    "survival": [4,5,6,7,8]
  },
  "Coagulations": {
    "birth": [3,7,8],
    "survival": [2,3,5,6,7,8]
  },
  "Walled Cities": {
    "birth": [4,5,6,7,8],
    "survival": [2,3,4,5]
  },
  
  
  "Spiky Vote": {
    "birth": [5,6,7,8],
    "survival": [3,5,6,7,8]
  },
  "Spiky Shrink": {
    "birth": [5,6,7,8],
    "survival": [2,5,6,7,8]
  },
  "Accumulation": {
    "description": "Fill up the grid with live cells, very gradually.",
    "birth": [2],
    "survival": [2,4,5,6,7,8]
  },
  
  
  "Epilepsy1": {
    "epilepsy": true,
    "birth": [0],
    "survival": [0,3,7,8]
  },
  "Epilepsy2": {
    "epilepsy": true,
    "birth": [0],
    "survival": [0,7,8]
  },
  "Epilepsy3": {
    "epilepsy": true,
    "birth": [0],
    "survival": [0,7]
  },
  "Epilepsy4": {
    "epilepsy": true,
    "birth": [0],
    "survival": [0,8]
  },
  
  
  "Wiggle Life": {
    "description": "Kind of like worms squiggling?",
    "birth": [3],
    "survival": [1,3]
  },
  "Mould": {
    "description": "It just keeps growing!",
    "birth": [3,7,8],
    "survival": [1,2,3,4,5,6,7,8]
  },
  "2x2 snakes": {
    "description": "Shrink to nice 2-width snakes.",
    "birth": [1,5],
    "survival": [0,3,4,5,7]
  },
  
  
  "(custom 1)": {
    "description": "Custom 1.",
    "custom": true,
    "birth": [],
    "survival": []
  },
  "(custom 2)": {
    "description": "Custom 2.",
    "custom": true,
    "birth": [],
    "survival": []
  },
  "(custom 3)": {
    "description": "Custom 3.",
    "custom": true,
    "birth": [],
    "survival": []
  }
}


/*

  "new1": {
    "birth": [3],
    "survival": [2]
  },
  "new2": {
    "birth": [3,6,7,8],
    "survival": [4]
  },
  "new3": {
    "birth": [8],
    "survival": [3,5,7]
  },
  "new4": {
    "birth": [],
    "survival": [1,7]
  },
  "new5": {
    "birth": [3,6,7,8],
    "survival": [2,4]
  },
  "new6": {
    "birth": [3,6,7,8],
    "survival": [2,5]
  },
  "new7": {
    "birth": [3,4,6],
    "survival": [5]
  },
  
  
  "new8": {
    "birth": [1,4,7],
    "survival": [2,3,4,6,7,8]
  }
  
*/


// Names of the rules.
loopTypes = {
  "Maze Cave": {
    "rules": [
      "MazeOfficial",
      "Vote"
    ]
  },
  "Coagulating Cities": {
    "description": "Works best with high loop frame values, a 99x99 size canvas, and a bit of blur.",
    "rules": [
      "Coagulations",
      "Walled Cities"
    ]
  },
  "Mould Cities": {
    "description": "Best with low loop frame value for mould, high frame for cities, and a bit of blur.",
    "rules": [
      "Mould",
      "Walled Cities"
    ]
  },
  "Accumulate/Shrink": {
    "description": "10 Accumulation frames, 5 Spiky Shrink frames. Add some blur. With a small centred initial state of 'on' cells, acts like a pulsing star.",
    "rules": [
      "Accumulation",
      "Spiky Shrink"
    ],
    "frames": [
      10,
      5
    ]
  },
  "Coral Growth": {
    "description": "",
    "rules": [
      "Accumulation",
      "Coral"
    ]
  },
  "Epilepsy Maze": {
    "description": "",
    "rules": [
      "Static Maze 2",
      "Epilepsy2"
    ]
  }
}

//##############################################################################

// Handle epilepsy rules.

// Toggle value of 'epilepsySafe' boolean.
function epilepsyToggle() {
  epilepsySafe = !epilepsySafe;
  var domObj = document.getElementById('button_epilepsy');
  if (epilepsySafe) {
    domObj.value = 'Epilepsy: Safe(ish)';
    domObj.style.background = '#BAD696'; // Green
    
    // Switch to a safe rule if current is unsafe.
    if (lifeRules[currentRuleType].hasOwnProperty('epilepsy')) {
      updateRuleByName('Conway');
    }
    if (lifeRules[loopRules[0]].hasOwnProperty('epilepsy')) {
      updateLoopRule(0, 'Conway');
    }
    if (lifeRules[loopRules[1]].hasOwnProperty('epilepsy')) {
      updateLoopRule(1, 'Conway');
    }
    
    document.getElementById('range_framerate').max = 10;
    if (frameRate > 10) { updateFramerate(10); }
    
  } else {
    domObj.value = 'Epilepsy: Unsafe';
    domObj.style.background = '#E94E77'; // Red
    
    document.getElementById('survival_0').style.display = 'block';
    document.getElementById('survival_1').style.display = 'block';
    
    document.getElementById('range_framerate').max = 60;
    
    // Just a QOL thing.
    // Since a safe 8 is the default, immediately switch to 20 if unchanged.
    if (frameRate == 8) { updateFramerate(20); }
  }
  
  // Reload the rules to the UI.
  HtmlLoopTypeDropDown();
  HtmlLifeRulesDropDowns();
  HtmlLoopTypeDropDown();
}

//########################################

// If epilepsySafe is on, then make sure birth and survival are not both 0.
function zeroNeighboursB() {
  if (epilepsySafe) {
    if (document.getElementById('birth_0').checked) {
      puts('epilepsySafe = ' + epilepsySafe);
      document.getElementById('survival_0').checked = false;
      document.getElementById('survival_0').style.display = 'none';
    } else {
      document.getElementById('survival_0').style.display = 'block';
    }
  }
}

function zeroNeighboursS() {
  if (epilepsySafe) {
    if (document.getElementById('survival_0').checked) {
      puts('epilepsySafe = ' + epilepsySafe);
      document.getElementById('birth_0').checked = false;
      document.getElementById('birth_0').style.display = 'none';
    } else {
      document.getElementById('birth_0').style.display = 'block';
    }
  }
}

//########################################
  
// Filter the rules according to what's valid.
// Mostly just to remove epileptic rules.
// This should be used instead of the raw [lifeRules].
function validLifeRules() {
  var outputHash = {};
  
  // If not epilepsy, then don't worry about flashing rules.
  if (!epilepsySafe) {
    outputHash = lifeRules;
    
  // If we are worried about epilepsy, filter out rules with 'epilepsy' tag.
  } else {
    for (var ruleName in lifeRules) {
      if (lifeRules.hasOwnProperty(ruleName)) {
        if (!lifeRules[ruleName].hasOwnProperty('epilepsy')) {
          outputHash[ruleName] = lifeRules[ruleName];
        }
      }
    }
  }
  return outputHash;
}

// Filter the loop types according to what's valid.
// Removes any with rules that are epileptic.
// This should be used instead of the raw [loopTypes].
function validLoopTypes() {
  var outputHash = {};
  
  // If not epilepsy, then don't worry about flashing rules.
  if (!epilepsySafe) {
    outputHash = loopTypes;
    
  // If we are worried about epilepsy, filter out rules with 'epilepsy' tag.
  } else {
    for (var loopName in loopTypes) {
      if (loopTypes.hasOwnProperty(loopName)) {
        epil_0 = lifeRules[ loopTypes[loopName]['rules'][0] ].hasOwnProperty('epilepsy');
        epil_1 = lifeRules[ loopTypes[loopName]['rules'][1] ].hasOwnProperty('epilepsy');
        if (!epil_0 && !epil_1) {
          outputHash[loopName] = loopTypes[loopName];
        }
      }
    }
  }
  return outputHash;
}

//##############################################################################

// Button toggles, pause and epilepsy.
function togglePause() {
  setPause(!paused);
}

function setPause(value) {
  paused = value;
  var domObj = document.getElementById('button_pause');
  if (paused) {
    domObj.style.background = '#E94E77'; // Red
  } else {
    domObj.style.background = ''; // Off
  }
}

//######################################

// Show/hide the description of the loop type.
var loopTypeDesc = true;
function toggleHtmlLoopTypeDesc() {
  loopTypeDesc = !loopTypeDesc;
  if (loopTypeDesc) {
    document.getElementById('loop_type_desc_toggle').innerHTML = '&nbsp;▼&nbsp;';
    document.getElementById('loop_type_desc').style.display = 'block';
  } else {
    document.getElementById('loop_type_desc_toggle').innerHTML = '&nbsp;▶&nbsp;';
    document.getElementById('loop_type_desc').style.display = 'none';
  }
}
toggleHtmlLoopTypeDesc();

// Show/hide the description of the loop type.
var rulesDesc = true;
function toggleHtmlRulesDesc() {
  rulesDesc = !rulesDesc;
  if (rulesDesc) {
    document.getElementById('rules_desc_toggle').innerHTML = '&nbsp;▼&nbsp;';
    document.getElementById('rules_desc').style.display = 'block';
  } else {
    document.getElementById('rules_desc_toggle').innerHTML = '&nbsp;▶&nbsp;';
    document.getElementById('rules_desc').style.display = 'none';
  }
}
toggleHtmlRulesDesc();

//##############################################################################

// Load JSON stuff to html objects.
function HtmlLifeRulesDropDowns() {
  var finalHtml = '';
  for (var property in validLifeRules()) {
    if (lifeRules.hasOwnProperty(property)) {
      finalHtml += '<option value="' + property + '">' + property + '</option>';
    }
  }
  document.getElementById('rules_select').innerHTML = finalHtml;
  document.getElementById('loop_rule_0').innerHTML = finalHtml;
  document.getElementById('loop_rule_1').innerHTML = finalHtml;
  
  document.getElementById('rules_select').value = currentRuleType;
  document.getElementById('loop_rule_0').value = loopRules[0];
  document.getElementById('loop_rule_1').value = loopRules[1];
}

function HtmlLoopTypeDropDown() {
  var finalHtml = '<option value="(none)">(none)</option>';
  finalHtml += '<option value="(custom)">(custom)</option>';
  for (var property in validLoopTypes()) {
    if (loopTypes.hasOwnProperty(property)) {
      finalHtml += '<option value="' + property + '">' + property + '</option>';
    }
  }
  document.getElementById('loop_type').innerHTML = finalHtml;
  document.getElementById('loop_type').value = '(none)';
}

//##############################################################################

var loopRules = ['Conway','Conway'];
var loopRates = [];

function updateRuleByIndex(index) {
  updateRuleByName( Object.keys(lifeRules)[index] );
}

function updateRuleByName(name) {
  currentRuleType = name;
  document.getElementById('rules_select').value = currentRuleType;
  
  // If it's a custom rule, then set the global variable.
  if (lifeRules[currentRuleType].hasOwnProperty('custom')) {
    lastCustomRuleName = currentRuleType;
  }
  
  // Reset the checkboxes to false.
  for (var i = 0; i <= 8; i++) {
    document.getElementById('birth_' + i).checked = false;
    document.getElementById('survival_' + i).checked = false;
  }
  
  // Turn checkboxes on if needed.
  for (var i = 0; i < lifeRules[currentRuleType]['birth'].length; i++) {
    document.getElementById('birth_' + lifeRules[currentRuleType]['birth'][i]).checked = true;
  }
  for (var i = 0; i < lifeRules[currentRuleType]['survival'].length; i++) {
    document.getElementById('survival_' + lifeRules[currentRuleType]['survival'][i]).checked = true;
  }
  
  // Show the description, if it has one.
  if (lifeRules[currentRuleType].hasOwnProperty('description')) {
    document.getElementById('rules_desc').innerHTML = lifeRules[currentRuleType]['description'];
  } else {
    document.getElementById('rules_desc').innerHTML = '';
  }
  
  // Epilepsy Life Rules checkboxes.
  zeroNeighboursS();
  zeroNeighboursB();
  
  puts('Rule = ' + currentRuleType);
}

//######################################

function updateLoopType(value) {
  loopType = value;
  document.getElementById('loop_type').value = loopType;
  
  // Reset the loop frame counter.
  frameCount = 0;
  
  if (loopType != '(none)' && loopType != '(custom)') {
    loopRules[0] = loopTypes[loopType]['rules'][0];
    loopRules[1] = loopTypes[loopType]['rules'][1];
    document.getElementById('loop_rule_0').value = loopRules[0];
    document.getElementById('loop_rule_1').value = loopRules[1];
    
    // Show the description, if it has one.
    if (loopTypes[loopType].hasOwnProperty('description')) {
      document.getElementById('loop_type_desc').innerHTML = loopTypes[loopType]['description'];
    } else {
      document.getElementById('loop_type_desc').innerHTML = '';
    }
    
    // Change the rule, if it is not one of the loop rules.
    if (currentRuleType != loopRules[0] && currentRuleType != loopRules[1]) {
      updateRuleByName(loopRules[0]);
    }
    puts('Loop Type = ' + loopType);
  }
}


// Flip the status of the labels' classes between "selected" and "unselected".
// Also, check the actual radio button.
function toggleRadioOn(domID, labelGroup) {
  document.getElementById(domID).checked = true;
  var labels = document.getElementsByClassName(labelGroup);
  for (var i = 0; i < labels.length; i++) {
    labels[i].classList.add('unselected');
    labels[i].classList.remove('selected');
  }
  var label = document.getElementById(domID+'_label');
  label.classList.add('selected');
  label.classList.remove('unselected');
}


var blurPercent;
function updateBlur(inputBlur) {
  blurPercent = parseInt(inputBlur);
	document.getElementById('range_blur').value = blurPercent;
	document.getElementById('span_blur').innerHTML = blurPercent + '%';
  var blurMax = 0.6;
  blur = blurMax - (blurMax * blurPercent / 100);
  if (blur == blurMax) { blur = 1; }
}
function updateFramerate(inputFramerate) {
  frameRate = parseInt(inputFramerate);
  interval = 1000/frameRate;
	document.getElementById('range_framerate').value = frameRate;
	document.getElementById('span_framerate').innerHTML = frameRate;
}

//##############################################################################

function updateColourLive(inputColour) {
  fillColourAlive = String(inputColour);
  if (fillColourAlive.charAt(0) != '#') {
    fillColourAlive = '#' + fillColourAlive;
  }
  document.getElementById('jscolor_live').jscolor.fromString(fillColourAlive);
  if (colourLiveIsBackground) {
    document.body.style.backgroundColor = fillColourAlive;
  }
}
function updateColourDead(inputColour) {
  fillColourDead = String(inputColour);
  if (fillColourDead.charAt(0) != '#') {
    fillColourDead = '#' + fillColourDead;
  }
  document.getElementById('jscolor_dead').jscolor.fromString(fillColourDead);
  if (colourDeadIsText) {
    document.body.style.color = fillColourDead;
    css('.border', 'border', '2px solid ' + fillColourDead);
  }
}

var colourLiveIsBackground = true;
var colourDeadIsText = true;
function setColourLiveIsBackground(value) {
  colourLiveIsBackground = value;
  document.getElementById('colour_live').checked = value;
}
function setColourDeadIsText(value) {
  colourDeadIsText = value;
  document.getElementById('colour_dead').checked = value;
}

//##############################################################################

// Change the loop rules.
function updateLoopRule(index, value) {
  loopRules[index] = value;
	document.getElementById('loop_rule_' + index).value = value;
  puts('updateLoopRule -- index:' + index + '  value:' + value);

  // Grab from the HTML selection.
  loopRule_0 = document.getElementById('loop_rule_0').value;
  loopRule_1 = document.getElementById('loop_rule_1').value;
  arrLoopRules = [loopRule_0, loopRule_1];
  arrLoopRules.sort();
  strLoopRules = JSON.stringify(arrLoopRules);
  
  // Loop to find a match.
  var loopTypeMatched = false;
  for (var loopName in loopTypes) {
    if (loopTypes.hasOwnProperty(loopName)) {
      
      rules = loopTypes[loopName]['rules'];
      rules.sort();
      rules = JSON.stringify(rules);
      puts(rules);
      
      if (rules == strLoopRules) {
        loopTypeMatched = true;
        document.getElementById('loop_type').value = loopName;
        puts('loopTypeMatched = true');
      }
    }
  }
  
  // Select 'Custom' if not rule matched.
  if (!loopTypeMatched) {
    document.getElementById('loop_type').value = '(custom)';
  }
}


// Change the loop rates.
function updateLoopRate(index, value) {
  loopRates[index] = value;
	document.getElementById('span_loop_rate_' + index).innerHTML = value;
  puts('updateLoopRate -- index:' + index + '  value:' + value);
}

//######################################

// Set the default options.
updateLoopRate(0, 20);
updateLoopRate(1, 20);
updateLoopRule(0, 'Conway');
updateLoopRule(1, 'Conway');
updateLoopType('(none)');

//##############################################################################

// Check to see if the chosen Birth/Survival checkboxes match an existing rule.
function checkLifeRules() {
  
  // Make arrays of each rule type.
  var birth = [];
  var survival = [];
  for (var i = 0; i <= 8; i++) {
    if (document.getElementById('birth_' + i).checked) {
      birth.push(i);
    }
    if (document.getElementById('survival_' + i).checked) {
      survival.push(i);
    }
  }
  
  // Convert to string for hacky array comparison.
  strBirth    = JSON.stringify(birth);
  strSurvival = JSON.stringify(survival);
  
  // Check each in { validLifeRules() } for a match.
  var ruleMatched = false;
  for (var ruleName in validLifeRules()) {
    if (lifeRules.hasOwnProperty(ruleName)) {
      
      // Convert to string for hacky array comparison.
      thisBirth    = JSON.stringify(lifeRules[ruleName]['birth']);
      thisSurvival = JSON.stringify(lifeRules[ruleName]['survival']);
      
      // Don't match to a 'custom' rule.
      var isCustom = lifeRules[ruleName].hasOwnProperty('custom');
      
      if (!isCustom && strBirth == thisBirth && strSurvival == thisSurvival) {
        puts('ruleMatched = true');
        
        // Select the rule.
        updateRuleByName(ruleName);
        ruleMatched = true;
      }
    }
  }
  
  // Select previous 'Custom' if not rule matched.
  if (!ruleMatched) {
    ruleName = lastCustomRuleName;
  
    // Update custom to the new options.
    lifeRules[ruleName]['birth'] = birth;
    lifeRules[ruleName]['survival'] = survival;
    document.getElementById('rules_select').value = ruleName;
    updateRuleByName(ruleName);
  }
}

//##############################################################################

function Cell(_x, _y) {
  this.x = _x * cellPixels.x;
  this.y = _y * cellPixels.y;
  this.stateNow = 0;
  this.stateNext = 0;
}
Cell.prototype.render = function() {
  this.stateNow = this.stateNext;
  // Don't render dead cells, to preserve the blur effect.
  if (this.stateNow != 0) {
    c.fillStyle = fillColourAlive;
    c.fillRect(this.x, this.y, cellPixels.x, cellPixels.y);
  }
}
// 'state' should be 0 or 1 for alive or dead.
Cell.prototype.setState = function(state) {
  c.fillStyle = (state == 0) ? fillColourDead : fillColourAlive;
  c.fillRect(this.x, this.y, cellPixels.x, cellPixels.y);
  this.stateNext = state;
  this.render();
}

// Run the neighbor check on each cell.
function nextStateAccordingToNeighbours(_x, _y) {
  var neighbors = [8];
  neighbors[0] = cells[(_x-1+cellCount.x)%cellCount.x][(_y-1+cellCount.y)%cellCount.y];
  neighbors[1] = cells[(_x-1+cellCount.x)%cellCount.x][_y];
  neighbors[2] = cells[(_x-1+cellCount.x)%cellCount.x][(_y+1)%cellCount.y];
  neighbors[3] = cells[_x][(_y-1+cellCount.y)%cellCount.y];
  neighbors[4] = cells[_x][(_y+1)%cellCount.y];
  neighbors[5] = cells[(_x+1)%cellCount.x][(_y-1+cellCount.y)%cellCount.y];
  neighbors[6] = cells[(_x+1)%cellCount.x][_y];
  neighbors[7] = cells[(_x+1)%cellCount.x][(_y+1)%cellCount.y];
  var n = 0;
  for(var i=0; i<8; i++) {
    if(neighbors[i].stateNow != 0) { n++; }
  }

  // Survival
  var booFound = false;
  for(var i=0; i<lifeRules[currentRuleType]['survival'].length; i++) {
    if(n==lifeRules[currentRuleType]['survival'][i]) { booFound = true; }
  }
  if(!booFound) { return false; }
  
  // Birth
  if (cells[_x][_y].stateNow == 0) {
    booFound = false;
    for(var i=0; i<lifeRules[currentRuleType]['birth'].length; i++) {
      if(n==lifeRules[currentRuleType]['birth'][i]) { booFound = true; }
    }
    if(!booFound) { return false; }
  }
  
  return true;
}

//##############################################################################

// Initialize a fraction of the cells to start in their "alive" state.
function randomise() {
  var limit = {x: cellCount.x, y: cellCount.y};
  if (mirrorNS) { limit.y = cellCount.y / 2; }
  if (mirrorEW) { limit.x = cellCount.x / 2; }
  
  for(var i = 0; i < limit.x; i++) {
    for(var j = 0; j < limit.y; j++) {
      var state = rand(0,1,1);
      
      // Change based on mirror variables.
      var coords = getMirrorCellCoords(i, j);
      for (var k = 0; k < coords.length; k++) {
        cells[ coords[k][0] ][ coords[k][1] ].setState(state);
      }
    }
  }
}

// Only works when width & height of the canvas is odd.
// Currently, use the UI to force an odd value.
function randomiseCentralBlock() {
  
  // Radius of central cells.
  var r = rand(2,Math.min(cellCount.x,cellCount.y)/2-10,1);
  
  // Set all the cells in the radius to live.
  var theCell = {x: 0,  y: 0};
  for(var i = -r; i <= r; i++) {
    for(var j = -r; j <= r; j++) {
      theCell.x = parseInt(centreCell.x) + parseInt(i);
      theCell.y = parseInt(centreCell.y) + parseInt(j);
      cells[theCell.x][theCell.y].stateNext = 1;
      cells[theCell.x][theCell.y].render();
    }
  }
}

// Kill them all, or revive them all.
function setAllCellsToState(state) {
  for(var i = 0; i < cellCount.x; i++) {
    for(var j = 0; j < cellCount.y; j++) {
      cells[i][j].stateNext = state;
      cells[i][j].render();
    }
  }
  if (state == 0) {
    c.fillStyle = fillColourDead;
    c.fillRect(0,0,w,h);
  }
}

//##############################################################################

function resizeCanvas() {
  a.width  = cellCount.x * cellPixels.x;
  a.height = cellCount.y * cellPixels.y;
  w = a.width;
  h = a.height;
}

//##############################################################################

// Draw the first scene.
function initCanvas() {
  cancelAnimationFrame(ANIMATION);
  then = Date.now();
  frameCount = 0;
  
  resizeCanvas();
  
  // Create empty cell object.
  cells = [cellCount.x];
  for (var i = 0; i < cellCount.x; i++) {
    cells[i] = new Array(cellCount.y);
  }
  for (var i = 0; i < cellCount.x; i++) {
    for (var j = 0; j < cellCount.y; j++) {
      cells[i][j] = new Cell(i,j);
    }
  }
  
  // Co-ords of central cell.
  centreCell = {
    x: Math.floor(cellCount.x/2),
    y: Math.floor(cellCount.y/2)
  };
  
  randomiseCentralBlock();
  drawScene();
  puts('ANIMATION='+ANIMATION);
}

// Redraw the whole canvas.
function clickRedrawButton() {
	cellCount.x = parseInt(document.getElementById('range_width').value);
	cellCount.y = parseInt(document.getElementById('range_height').value);
	cellPixels.x = cellPixels.y = parseInt(document.getElementById('range_pixels').value);
  initCanvas();
}


// Step frames individually.
var stepToNextFrame = false;
function stepFrame() {
  paused = false;
  togglePause();
  stepToNextFrame = true;
}


//functionality
// http://codetheory.in/controlling-the-frame-rate-with-requestanimationframe/
var now, then, delta, interval = 1000/frameRate;
var globalStateStatic;
function drawScene() {
  ANIMATION = requestAnimationFrame(drawScene);
  
  now = Date.now();
  delta = now - then;
  if (!paused && delta > interval || stepToNextFrame) {
    then = now - (delta % interval);
    stepToNextFrame = false;
    
    dead = hexToRgb(fillColourDead);
    c.fillStyle = 'rgba(' + dead.r + ', ' + dead.g + ', ' + dead.b + ', ' + blur + ')';
    c.fillRect(0,0,w,h);

    // Display cells.
    for(var i = 0; i < cellCount.x; i++) {
      for(var j = 0; j < cellCount.y; j++) {
        cells[i][j].render();
      }
    }
    
    // Calculate next state.
    globalStateStatic = true;
    for(var i = 0; i < cellCount.x; i++) {
      for(var j = 0; j < cellCount.y; j++) {
        var state = !nextStateAccordingToNeighbours(i,j) ? 0 : 1;
        if (cells[i][j].stateNext != state) {
          cells[i][j].stateNext = state;
          globalStateStatic = false;
        }
      }
    }
    
    // Have we reached a no-change state?
    // (Might use this in the future...)
    if (globalStateStatic == true) {
      puts('dead');
    }
    
    loopFunctions();
  }
}

// Move to next rule in the loop, if necessary.
function loopFunctions() {
  if (loop_type.value != '(none)') {
    frameCount++;
    if (frameCount >= loopRates[loopState]) {
      frameCount = 0;
      
      // Currently handles just 2 states.
      loopState = (loopState == 0) ? 1 : 0;
      updateRuleByName(loopRules[loopState]);
    }
  }
}

//##############################################################################

// Mirrored drawing.
function toggleMirrorNS() {
  mirrorNS = !mirrorNS;
  document.getElementById('mirror_NS').checked = mirrorNS;
}
function toggleMirrorEW() {
  mirrorEW = !mirrorEW;
  document.getElementById('mirror_EW').checked = mirrorEW;
}
function toggleMirrorNESW() {
  mirrorNESW = !mirrorNESW;
  document.getElementById('mirror_NESW').checked = mirrorNESW;
}
function toggleMirrorNWSE() {
  mirrorNWSE = !mirrorNWSE;
  document.getElementById('mirror_NWSE').checked = mirrorNWSE;
}

//######################################

// Same above as below. (X is the same)
function getMirrorNS(_x, _y) {
  return [_x , (cellCount.y - 1) - _y];
}
// Same left as right. (Y is the same)
function getMirrorEW(_x, _y) {
  return [(cellCount.x - 1) - _x , _y];
}

//######################################

// Diagonals - Works best with square canvas. Will cut off sides if longer.
function getMirrorNESW(_x, _y) {
  return getMirrorDiagonal(_x, _y, 1);
}
function getMirrorNWSE(_x, _y) {
  return getMirrorDiagonal(_x, _y, -1);
}

// posOrNeg is 1 if NESW, -1 if NWSE.
function getMirrorDiagonal(_x, _y, posOrNeg) {
  
  // Difference between the central cell and input.
  var xDiff = centreCell.x - _x;
  var yDiff = centreCell.y - _y;
  
  // Add the other co-ordinate's value.
  var xValue = centreCell.x + (yDiff * posOrNeg);
  var yValue = centreCell.y + (xDiff * posOrNeg);
  
  // If it's not in a drawable region, then just return the original.
  if (xValue >= 0 && xValue < cellCount.x && yValue >= 0 && yValue < cellCount.y) {
    return [xValue, yValue];
  } else {
    return [_x, _y];
  }
}

var mirrorNS = false;
var mirrorEW = false;
var mirrorNESW = false;
var mirrorNWSE = false;
toggleMirrorNS();
toggleMirrorEW();
toggleMirrorNESW();
toggleMirrorNWSE();

//######################################

// This will return an array of cell addresses.
function getMirrorCellCoords(_x, _y) {
  var coords = new Array();
  coords[0] = [_x, _y];
  
  if (mirrorNS) {
    coords.push( getMirrorNS(_x, _y) );
  }
  
  // There might now be two values in [coords], so loop through.
  if (mirrorEW) {
    var loopMax = coords.length;
    for (var i = 0; i < loopMax; i++) {
      coords.push( getMirrorEW(coords[i][0], coords[i][1]) );
    }
  }
  
  // Same again for the diagonal mirrors.
  if (mirrorNESW) {
    var loopMax = coords.length;
    for (var i = 0; i < loopMax; i++) {
      coords.push( getMirrorNESW(coords[i][0], coords[i][1]) );
    }
  }
  if (mirrorNWSE) {
    var loopMax = coords.length;
    for (var i = 0; i < loopMax; i++) {
      coords.push( getMirrorNWSE(coords[i][0], coords[i][1]) );
    }
  }
  
  return coords;
}

//##############################################################################

// Call this on events 'mousedown' and 'mousemove'.
var mouse = {x: 0, y: 0};
function drawCellFromMousePos(e) {
  if (mouseDown) {
    
    // Left click for live, middle click for dead.
    var state = (e.which == 2) ? 0 : 1;
    
    // Determine cell x/y from mouse x/y
    mouse.x = e.pageX - a.offsetLeft;
    mouse.y = e.pageY - a.offsetTop;
    _x = Math.max(0,Math.floor(mouse.x / cellPixels.x));
    _y = Math.max(0,Math.floor(mouse.y / cellPixels.y));
    
    // Change based on mirror variables.
    var coords = getMirrorCellCoords(_x, _y);
    for (var i = 0; i < coords.length; i++) {
      cells[ coords[i][0] ][ coords[i][1] ].setState(state);
    }
  }
}

// Really simple way of determining if mousedown.
var mouseDown = false;
a.addEventListener('mousedown', function(e) {
  mouseDown = true;
  drawCellFromMousePos(e);
}, false);
a.addEventListener('mouseup', function(e) {
  mouseDown = false;
}, false);

a.addEventListener('mousemove', function(e) {
  drawCellFromMousePos(e);
}, false);

// Disable canves doubleclick selection.
// http://stackoverflow.com/a/3799700/139299
a.onmousedown = function() {
  return false;
};

//##############################################################################

// http://javascript.info/tutorial/keyboard-events
function getChar(event) {
  if (event.which == null) {
    return String.fromCharCode(event.keyCode) // IE
  } else if (event.which!=0 && event.charCode!=0) {
    return String.fromCharCode(event.which)   // the rest
  } else {
    return null // special key
  }
}
document.onkeypress = function(event) {
  var char = getChar(event || window.event);
  if (!char) return;
  keys = Object.keys(lifeRules);
  switch( char.toUpperCase() ) {
    case 'P': togglePause(); break;
    case '1': updateRuleByIndex(0); break;
    case '2': updateRuleByIndex(1); break;
    case '3': updateRuleByIndex(2); break;
    case '4': updateRuleByIndex(3); break;
    case '5': updateRuleByIndex(4); break;
    case '6': updateRuleByIndex(5); break;
    case '7': updateRuleByIndex(6); break;
    case '8': updateRuleByIndex(7); break;
    case '9': updateRuleByIndex(8); break;
    case '0': updateRuleByIndex(9); break;
    
    case 'Q': randomise(); break;
    case 'W': randomiseCentralBlock(); break;
    
    case 'Z': setAllCellsToState(1); break;
    case 'X': setAllCellsToState(0); break;
    
    default: break;
  }
  return false;
}

// Step frame on spacebar press.
window.addEventListener('keydown', function(e) {
  if (e.keyCode == 32) {
    stepFrame();
  }
});

// Disable default space scroll down behaviour.
window.onkeydown = function(e) {
  return !(e.keyCode == 32);
};

// Pause and get a blank screen.
function clearCanvas() {
  paused = false;
  togglePause();
  setAllCellsToState(1);
}

//##############################################################################

// Init function.
(function() {
  a.width  = cellCount.x * cellPixels.x;
  a.height = cellCount.y * cellPixels.y;
  updateRuleByName(currentRuleType);
  updateBlur(0);
  updateFramerate(frameRate);
  initCanvas();
  epilepsySafe = false;
  epilepsyToggle();
  HtmlLifeRulesDropDowns();
  HtmlLoopTypeDropDown();
  updateDOMInnerHTML('span_width',cellCount.x);
  updateDOMInnerHTML('span_height',cellCount.y);
  setColourLiveIsBackground(true);
  setColourDeadIsText(true);
//  addEventListener('resize', initCanvas, false);
})();

//##############################################################################

// Get state of all cells.
function stateSave() {
  states = 'cellState='
  for(var i = 0; i < cellCount.x; i++) {
    for(var j = 0; j < cellCount.y; j++) {
      states += cells[i][j].stateNow;
    }
  }
  
  states += ',cellCount.x=' + cellCount.x;
  states += ',cellCount.y=' + cellCount.y;
  states += ',cellPixels.x=' + cellPixels.x;
  states += ',cellPixels.y=' + cellPixels.y;
  states += ',frameRate=' + frameRate;
  states += ',blurPercent=' + blurPercent;
  states += ',fillColourDead=' + fillColourDead;
  states += ',fillColourAlive=' + fillColourAlive;
  states += ',currentRuleType=' + currentRuleType;
  
  states = lzw_encode(states);

	document.getElementById('state_text').value = states;
  document.getElementById('state_text').select();
}


// Get state of all cells.
function stateLoad() {
	fullState = document.getElementById('state_text').value;
  fullState = lzw_decode(fullState);
  
	document.getElementById('state_text').value = fullState;
  
  // Load the variables first, before we draw the cells.
  var states = fullState.split(',');
  for (var i=1; i<states.length; i++) {
    
    // 'states[i]' is in the form 'variable="value"'
    split = states[i].split('=');
    variable = split[0];
    value = split[1];
    
    // Change the required variable.
    switch( variable ) {
      case 'cellCount.x':
        updateDOMValue('range_width',value);
        updateDOMInnerHTML('span_width',value);
        break;
      case 'cellCount.y':
        updateDOMValue('range_height',value);
        updateDOMInnerHTML('span_height',value);
        break;
      case 'cellPixels.x':
        updateDOMValue('range_pixels',value);
        updateDOMInnerHTML('span_pixels',value);
        break;
  /*  case 'cellPixels.y':
        updateDOMInnerHTML('span_pixels',value);
        break;  */
      case 'frameRate':
        updateFramerate(value);
        break;
      case 'blurPercent':
        updateBlur(value);
        break;
      case 'fillColourDead':
        updateColourDead(value);
        break;
      case 'fillColourAlive':
        updateColourLive(value);
        break;
      case 'currentRuleType':
        updateRuleByName(value)
        break;
      default: break;
    }
  }
  
  // Redraw the canvas.
  clickRedrawButton();
  
  // Load the cell states to the canvas.
  cellStateString = String( states[0].split('=')[1] );
  
  // Loop through all the cells.
  for(var i = 0; i < cellCount.x; i++) {
    for(var j = 0; j < cellCount.y; j++) {
      
      // Set the state.
      state = parseInt( cellStateString.charAt(0) );
      cells[i][j].setState(state);
      
      // Remove the first character of the string.
      cellStateString = cellStateString.substring(1)
    }
  }
}

// https://gist.github.com/revolunet/843889
// LZW-compress a string
function lzw_encode(s) {
  var dict = {};
  var data = (s + "").split("");
  var currChar;
  var phrase = data[0];
  var out = [];
  var code = 256;
  for (var i=1; i<data.length; i++) {
    currChar=data[i];
    if (dict['_' + phrase + currChar] != null) {
      phrase += currChar;
    }
    else {
      out.push(phrase.length > 1 ? dict['_'+phrase] : phrase.charCodeAt(0));
      dict['_' + phrase + currChar] = code;
      code++;
      phrase=currChar;
    }
  }
  out.push(phrase.length > 1 ? dict['_'+phrase] : phrase.charCodeAt(0));
  for (var i=0; i<out.length; i++) {
    out[i] = String.fromCharCode(out[i]);
  }
  return out.join("");
}

// Decompress an LZW-encoded string
function lzw_decode(s) {
  var dict = {};
  var data = (s + "").split("");
  var currChar = data[0];
  var oldPhrase = currChar;
  var out = [currChar];
  var code = 256;
  var phrase;
  for (var i=1; i<data.length; i++) {
    var currCode = data[i].charCodeAt(0);
    if (currCode < 256) {
      phrase = data[i];
    }
    else {
      phrase = dict['_'+currCode] ? dict['_'+currCode] : (oldPhrase + currChar);
    }
    out.push(phrase);
    currChar = phrase.charAt(0);
    dict['_'+code] = oldPhrase + currChar;
    code++;
    oldPhrase = phrase;
  }
  return out.join("");
}
