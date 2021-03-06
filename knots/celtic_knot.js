
// Class to generate Celtic knots.
let CelticKnot = (function(undefined) {

  // These are the characters that the Knots font uses.
  // The key string represents the boundaries at NESW.
  // 0 = Blocked
  // 1 = Crossed
  // 2 = Straight
  let boxChars = {
    "2222": "╋",
    "2122": "╉",
    "2022": "┫",
    "2221": "╊",
    "2121": "╂",
    "2021": "┨",
    "2220": "┣",
    "2120": "┠",
    "2020": "┃",
    "2212": "╇",
    "2112": "╃",
    "2012": "┩",
    "2211": "╄",
    "2111": "╀",
    "2011": "┦",
    "2210": "┡",
    "2110": "┞",
    "2010": "╿",
    "2202": "┻",
    "2102": "┹",
    "2002": "┛",
    "2201": "┺",
    "2101": "┸",
    "2001": "┚",
    "2200": "┗",
    "2100": "┖",
    "2000": "╏",
    "1222": "╈",
    "1122": "╅",
    "1022": "┪",
    "1221": "╆",
    "1121": "╁",
    "1021": "┧",
    "1220": "┢",
    "1120": "┟",
    "1020": "╽",
    "1212": "┿",
    "1112": "┽",
    "1012": "┥",
    "1211": "┾",
    "1111": "┼",
    "1011": "┤",
    "1210": "┝",
    "1110": "├",
    "1010": "│",
    "1202": "┷",
    "1102": "┵",
    "1002": "┙",
    "1201": "┶",
    "1101": "┴",
    "1001": "┘",
    "1200": "┕",
    "1100": "└",
    "1000": "┈",
    "0222": "┳",
    "0122": "┱",
    "0022": "┓",
    "0221": "┲",
    "0121": "┰",
    "0021": "┒",
    "0220": "┏",
    "0120": "┎",
    "0020": "╻",
    "0212": "┯",
    "0112": "┭",
    "0012": "┑",
    "0211": "┮",
    "0111": "┬",
    "0011": "┐",
    "0210": "┍",
    "0110": "┌",
    "0010": "╷",
    "0202": "━",
    "0102": "╾",
    "0002": "╸",
    "0201": "╼",
    "0101": "─",
    "0001": "╴",
    "0200": "╺",
    "0100": "╶",
    "0000": "&nbsp;&nbsp;&nbsp;&nbsp;"
  }

  // Class functions.
  let cf = {};

  // Find the box character using the input's n,e,s,w attributes.
  cf.boxCharFromDirs = function(obj) {
    dir = "" + obj.n + obj.e + obj.s + obj.w;
    return boxChars[dir];
  };

  // Simple and stupid method for getting a weighted sample.
  cf.weightedRandom = function(values, weights) {
    let arr = [];
    for (let i = 0; i < weights.length; i++) {
      for (let j = 0; j < weights[i]; j++) {
        arr.push(values[i]);
      }
    }
    return arr[Math.floor(Math.random()*arr.length)] || 0;
  };

  // Create an array of the boundaries between characters.
  // Horizontal is East and West, vertical is North and South.
  // Mirror for symmetry.
  cf.boundaries = function(length, boundaryWeights) {
    let output = [];
    for (let i = 0; i < length - 1; i++) {
      let mirrorI = length - i - 2;
      if ( output[mirrorI] != undefined ) {
        output[i] = output[mirrorI];
      } else {
        output[i] = cf.weightedRandom([0,1,2], boundaryWeights);
      }
    }
    return output;
  }

  // Instance variables and functions.
  function CelticKnot() {
    this.width  = 20;
    this.height = 8;
    this.boundaryWeights = [2,2,2];

    // Generate a knot based on the instance variables.
    this.gen = function() {
      let width = this.width, height = this.height;

      // The final array that will be output.
      let knotArray = [];
      for (let y = 0; y < height; y++) {
        knotArray[y] = [];
        for (let x = 0; x < width; x++) {
          knotArray[y][x] = {n: 0, e: 0, s: 0, w: 0};
        }
      }

      // Create an array of the boundaries between characters.
      let boundariesHoriz = [];
      for (let i = 0; i < height; i++) {
        let mirrorI = height - i - 1;
        if ( boundariesHoriz[mirrorI] != undefined ) {
          boundariesHoriz[i] = boundariesHoriz[mirrorI];
        } else {
          boundariesHoriz[i] = cf.boundaries(width, this.boundaryWeights);
        }
      }

      // Map the boundaries to the knotArray.
      for (let y = 0; y < boundariesHoriz.length; y++) {
        for (let x = 0; x < boundariesHoriz[0].length; x++) {
          knotArray[y][x].e   = boundariesHoriz[y][x];
          knotArray[y][x+1].w = boundariesHoriz[y][x];
        }
      }

      // Create an array of the boundaries between rows.
      let boundariesVert = [];
      for (let i = 0; i < width; i++) {
        let mirrorI = width - i - 1;
        if ( boundariesVert[mirrorI] != undefined ) {
          boundariesVert[i] = boundariesVert[mirrorI];
        } else {
          boundariesVert[i] = cf.boundaries(height, this.boundaryWeights);
        }
      }

      // Map the boundaries to the knotArray.
      for (let x = 0; x < boundariesVert.length; x++) {
        for (let y = 0; y < boundariesVert[0].length; y++) {
           knotArray[y][x].s   = boundariesVert[x][y];
           knotArray[y+1][x].n = boundariesVert[x][y];
        }
      }

      // Find the char that matches the directions.
      let finalHtml = "";
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          finalHtml += cf.boxCharFromDirs(knotArray[y][x]);
        }
        finalHtml += "<br>";
      }

      // Return the html string.
      return finalHtml;
    }
  };

  return CelticKnot;

})();
