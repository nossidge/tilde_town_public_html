#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Make an HTML page more ａｅｓｔｈｅｔｉｃ
# https://lingojam.com/VaporwaveTextGenerator
################################################################################

require "moji"      # To convert strings from half- to full-width.
require "nokogiri"  # To read in the HTML.

################################################################################

css_aesthetic = %Q|
  body {
    background:
      url(http://i.imgur.com/lxlKDQF.gif),
      url(http://i.imgur.com/LGBqAPT.gif),
      url(http://i.imgur.com/Oq9oNsj.gif),
      url(http://i.imgur.com/f6yFAA3.gif),
      url(http://i.imgur.com/RWnEoy0.jpg)
    ;
    background-position:
      bottom right,
      bottom left,
      top right,
      top left,
      center
    ;
    background-repeat: no-repeat;
    background-attachment: fixed;
    background-size: auto;
    text-decoration: normal;
    -o-text-overflow: clip;
    text-overflow: clip;
    color: rgba(0,222,0,1);
    text-shadow:
      0 0 10px rgba(99,222,77,1),
      0 0 20px rgba(99,222,77,1),
      0 0 30px rgba(99,222,77,1)
    ;
    -webkit-transition: all 200ms cubic-bezier(0.42, 0, 0.58, 1);
    -moz-transition:    all 200ms cubic-bezier(0.42, 0, 0.58, 1);
    -o-transition:      all 200ms cubic-bezier(0.42, 0, 0.58, 1);
    transition:         all 200ms cubic-bezier(0.42, 0, 0.58, 1);
  }
  div.box, iframe.box {
    border: 3px solid rgba(0,222,0,1);
  }|.sub("\n",'')

################################################################################

# Load my precious index.html to a variable.
# Make sure to specify UTF8, or String#sub will fail.
index_html = File.open("index.html", "r:UTF-8", &:read)

# Parse the HTML using nokogiri.
doc = Nokogiri::HTML.parse(index_html)

# Get rid of any <script> tags and comments.
# Select only the <body>.
html_to_replace = doc
  .xpath("//script").remove
  .xpath('//comment()').remove
  .xpath("//html//body")

# Loop through each line of the HTML.
# Replace half-width with full-width.
# Replace last occurrence only.
output_lines = []
html_to_replace.to_s.split("\n").each do |line|
  line_parse = Nokogiri::HTML.parse(line)
  half = line_parse.text
  full = Moji.han_to_zen(line_parse.text)
  new_line = line.reverse.sub(half.reverse, full.reverse).reverse
  output_lines << new_line

  # Manually fix the few lines that don't auto-convert.
  # Output to console and then search/replace.
  if (half != full) and (new_line == line)
    puts '########################################'
    puts line
  end
end

# Build up the HTML using the same head as the original.
output_html  = "<html>"
output_html += doc.xpath("//html//head").to_html
output_html += output_lines.join("\n")
output_html += "<html>"

# Read that back in with nokogiri.
# Add the new CSS, as an extra <style> node.
newdoc = Nokogiri::HTML.parse(output_html)
style = newdoc.at_css "style"
style.add_next_sibling "<style>#{css_aesthetic}</style>"

# Save to a new file.
File.open("index_aesthetic_generated.html", "w") do |file|
  file.write newdoc.to_html
end

################################################################################
