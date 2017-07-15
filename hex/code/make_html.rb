#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Make 'index.html'
# Read in the part-of-speech array from 'css_words_pos.rb'
# Output as a Tracery-friendly structure in the HTML.
################################################################################

require_relative 'css_words_pos'
require 'json'

################################################################################

# Sort by keys, to make it more human-readable.
def sort_hash input
  output = {}
  input.keys.sort.each do |k|
    output[k] = input[k]
  end
  output
end

################################################################################

# Create a hash of arrays like: { pos => [word1, word2, ...] }
by_pos = Hash.new { |h,k| h[k] = [] }
CSSColours::WORDS_POS.each do |i|
  i[1].each do |pos|
    by_pos[pos] << i[0]
  end
end

# Convert the hash to JSON, and format it.
json = sort_hash(by_pos).to_json
json = json.gsub('],"',"],\n#{' '*8}\"")
json = json.gsub(/[{}]/,'') + ','

# Output the JSON to the HTML file.
File.open('../index.html', 'w') do |fo|
  File.open('index_template.html', 'r') do |fi|
    out = fi.read.gsub('/* Ruby will populate this */', json)
    fo.puts out
  end
end

################################################################################
