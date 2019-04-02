var PLAINTEXT_CHORDS = ( function(mod) {

  // Parse the plain-text to separate divs
  mod.apply = function() {
    convertPlaintext();
    addButtons();
  };

  // Redraw the chord divs based on the new semitone delta
  mod.redraw = function(delta) {
    let chordDivs = document.getElementsByClassName('pc_chord');
    for (let div of chordDivs) {
      let extractedChords = extractChords(div.innerText);
      let maxLen = Math.max(...Object.keys(extractedChords));
      let strFinal = '';
      for (let i = 0; i <= maxLen; i++) {
        let chordOrig = extractedChords[i]
        if (chordOrig) {
          let chordTrans = transposeChord(chordOrig, delta);
          strFinal += chordTrans;
          i += (chordTrans.length - 1);
        } else {
          strFinal += ' ';
        }
      }
      div.innerText = strFinal;
    }
  };

  // Convert the plain-text into chord and lyric lines
  function convertPlaintext() {
    let lyricDiv = document.getElementById('plaintext_chords');
    let lyricLines = lyricDiv.innerHTML.split('\n');
    let html = '';
    for(let i = 0; i < lyricLines.length; i++){
      let line = lyricLines[i];
      let isChords = (line.search('   ') >= 0);
      let lineClass = (isChords ? 'pc_chord' : 'pc_lyric');
      if (line == '' && html != '') line = '&nbsp;';
      html += '<pre class="pc ' + lineClass + '">' + line + '</pre>';
    }
    lyricDiv.innerHTML = html;
  }

  // Prepend the button controls to the top of the body
  function addButtons() {
    let buttonDiv = document.createElement('div');
    buttonDiv.innerHTML = `
      <button type="button" class="pc_button" onclick="PLAINTEXT_CHORDS.redraw(-1)">◄</button>
      <button type="button" class="pc_button" onclick="PLAINTEXT_CHORDS.redraw(1)">►</button>
    `;
    document.getElementById('plaintext_chords').prepend(buttonDiv);
  }

  // Transpose chord up or down a number of semitones
  // https://stackoverflow.com/a/45979883/139299
  function transposeChord(chord, delta) {
    let scale = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
    ];
    let normalizeMap = {
      'Cb':'B',  'Db':'C#', 'Eb':'D#',
      'Fb':'E',  'Gb':'F#', 'Ab':'G#',
      'Bb':'A#', 'E#':'F',  'B#':'C'
    };
    let preferred = {
      'D#':'Eb', 'G#':'Ab', 'A#':'Bb'
    };
    return chord.replace(/[CDEFGAB](b|#)?/g, function(match) {
      let note = (normalizeMap[match] ? normalizeMap[match] : match);
      let index = (scale.indexOf(note) + delta) % scale.length;
      let newNote = scale[ index < 0 ? index + scale.length : index ];
      return (preferred[newNote] ? preferred[newNote] : newNote);
    });
  }

  // Return hash containing each chord's string position
  // Example:  {0: "Bbm", 14: "Eb", 43: "F#m", 68: "C#"}
  function extractChords(str) {
    let output = {};
    let processing = false;
    let chord, chordPos;
    for (let i = 0; i < str.length; i++) {
      let char = str.charAt(i);
      if (!processing && char != ' ') {
        processing = true;
        chord = '';
        chordPos = i;
      } else if (processing && char == ' ') {
        processing = false;
        output[chordPos] = chord;
      }
      if (processing) chord += char;
    }
    if (processing) output[chordPos] = chord;
    return output;
  }

  return mod;
}(PLAINTEXT_CHORDS || {}));

window.addEventListener('load', PLAINTEXT_CHORDS.apply);
