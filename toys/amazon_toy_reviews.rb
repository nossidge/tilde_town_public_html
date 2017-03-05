#!/usr/bin/env ruby
# encoding: UTF-8

################################################################################
# 2014/12/22  tilde.town/~nossidge  amazon_toy_reviews.rb
################################################################################

require 'scalpel'
# Scalpel is not perfect. Here's an example;
#   s = 'I am a lion. Hear me roar! "Where is my cub?" Never mind, found him.'
#   puts Scalpel.cut(s)
# Should be okay for this text corpus though.

################################################################################

TEMPLATE_FILE_HTML = 'toys_template.html'
OUTPUT_FILE_HTML = 'index.html'

################################################################################

class String
  def first_between_two_chars(char = '"')
    between = scan(/#{char}([^#{char}]*)#{char}/).first
    between.join if between
  end
end
  
################################################################################

linesFirst = []
linesRest = []
File.open('amazon_toy_reviews.txt', 'r').each_line do |line|
  line.strip!
  if line != '' and line.chars.first != '#'
    lines = Scalpel.cut(line)
    linesFirst << lines.first
    if lines.length > 1
      lines[1..-1].each do |i|
        linesRest << i
      end
    end
  end
end

def get_review(linesFirst,linesRest)
  line = linesFirst.sample
  loop do
    selectedLine = linesRest.sample
    line = line + ' ' + selectedLine
    break if line.length >= 160
  end
  line
end

################################################################################

# Sorry mumsnet...
def get_image_urls
  require 'mechanize'
  output = []
  mechanize = Mechanize.new
  page = mechanize.get('http://www.mumsnet.com/reviews/toys-and-gifts/toys-for-babies')
  page.search('img').each do |i|
    if i.to_s.match('img src="/images/reviews/thumbnails')
      output.push 'http://static.mumsnet.com' + i.to_s.first_between_two_chars('"')
    end
  end
  output
end
imageURLs = get_image_urls

################################################################################

htmlElemsP = []
(0..40).each do |i|
  review = get_review(linesFirst,linesRest)
  randImg = imageURLs.sample
  htmlElemsP.push "<p><img src='#{randImg}' height='100' width='100'>#{review}</p>"
end

File.open(OUTPUT_FILE_HTML, 'w') do |fo|
  File.open(TEMPLATE_FILE_HTML, 'r') do |fi|
    out = fi.read.gsub('<!-- @TOYS_LIST -->', htmlElemsP.join("\n"))
    fo.puts out
  end
end

################################################################################

