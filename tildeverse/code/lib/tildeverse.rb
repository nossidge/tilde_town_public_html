#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Tildeverse Users Scraper
# ~nossidge/public_html/tildeverse/tildeverse.rb
################################################################################
# Get a list of all users in the Tildeverse.
# Mostly done using HTML scraping, but there are few JSON feeds.
# Lots of copy-pasting going on here. Each tilde is in a separate function.
#   I figured it was best to do it this way as no two Tildes are the same,
#   scraping wise. It wouldn't make sense to try to work out commonalities.
################################################################################

require 'net/http'
require 'net/https'
require 'open-uri'
require 'json'
require 'twitter'
require 'text/hyphen'

require_relative 'tildeverse/core_extensions/string.rb'
require_relative 'tildeverse/tilde_connection.rb'
require_relative 'tildeverse/read_sites.rb'
require_relative 'tildeverse/misc.rb'

################################################################################

# Load my personal Twitter API keys.
if Gem.win_platform?
  require 'C:\Dropbox\Code\Ruby\tweeter\tweeter.rb'
else
  require '/home/nossidge/code/tweeter/tweeter.rb'
end

Tweeter.dev_mode
TWITTER_ACCOUNT  = 'the_tildeverse'
#TWITTER_ACCOUNT  = 'NossidgeTest'

################################################################################

TEMPLATE_FILE_HTML    = File.dirname(__FILE__) +'/../users_template.html'
OUTPUT_FILE_HTML      = File.dirname(__FILE__) +'/../../users.html'
OUTPUT_FILE_JSON      = File.dirname(__FILE__) +'/../../users.json'
OUTPUT_FILE_JSON_PREV = File.dirname(__FILE__) +'/../../users_prev.json'

WRITE_TO_FILES          = true   # This is necessary.
CHECK_FOR_NEW_BOXES     = false  # This is fast.
CHECK_FOR_NEW_DESC_JSON = false  # This is slow.
TRY_KNOWN_DEAD_SITES    = false  # This is pointless.
TWEET_USER_DIFFS        = false  # This is broken.

################################################################################

module Tildeverse

################################################################################

def self.output_to_files
  read_all_to_hash = lambda do
    userHash = {}
    userHash['https://backtick.town'] = read_backtick_town
    userHash['https://bleepbloop.club'] = read_bleepbloop_club
    userHash['https://botb.club'] = read_botb_club
    userHash['http://catbeard.city'] = read_catbeard_city
    userHash['https://club6.nl'] = read_club6_nl
    userHash['https://crime.team'] = read_crime_team
    userHash['http://ctrl-c.club'] = read_ctrl_c_club
    userHash['http://cybyte.club'] = read_cybyte_club
    userHash['http://drawbridge.club'] = read_drawbridge_club
    userHash['http://germantil.de'] = read_germantil_de
    userHash['http://hackers.cool'] = read_hackers_cool
    userHash['http://hypertext.website'] = read_hypertext_website
    userHash['http://losangeles.pablo.xyz'] = read_losangeles_pablo_xyz
    userHash['http://matilde.club'] = read_matilde_club
    userHash['http://noiseandsignal.com'] = read_noiseandsignal_com
    userHash['https://ofmanytrades.com'] = read_ofmanytrades_com
    userHash['http://oldbsd.club'] = {}
    userHash['http://palvelin.club'] = read_palvelin_club
    userHash['http://pebble.ink'] = read_pebble_ink
    userHash['http://perispomeni.club'] = read_perispomeni_club
    userHash['http://protocol.club'] = read_protocol_club
    userHash['https://remotes.club'] = read_remotes_club
    userHash['http://retronet.net'] = read_retronet_net
    userHash['http://riotgirl.club'] = read_riotgirl_club
    userHash['http://rudimentarylathe.org'] = read_rudimentarylathe_org
    userHash['http://skylab.org'] = read_skylab_org
    userHash['https://spookyscary.science'] = read_spookyscary_science
    userHash['https://squiggle.city'] = read_squiggle_city
    userHash['http://sunburnt.country'] = read_sunburnt_country
    userHash['http://tilde.camp'] = read_tilde_camp
    userHash['https://tilde.center'] = read_tilde_center
    userHash['http://tilde.city'] = read_tilde_city
    userHash['http://tilde.club'] = read_tilde_club
    userHash['http://tilde.farm'] = read_tilde_farm
    userHash['https://tilde.red'] = read_tilde_red
    userHash['https://tilde.town'] = read_tilde_town
    userHash['http://tilde.works'] = read_tilde_works
    userHash['http://tildesare.cool'] = read_tildesare_cool
    userHash['http://totallynuclear.club'] = read_totallynuclear_club
    userHash['http://yester.host'] = read_yester_host
    sort_hash_by_keys(userHash)
    userHash
  end
  all_hash = read_all_to_hash.call

  # Rename the existing JSON with 'previous' file name.
  File.rename(OUTPUT_FILE_JSON, OUTPUT_FILE_JSON_PREV)

  # Write to JSON while we have the hash.
  File.open(OUTPUT_FILE_JSON,'w') do |f|
    f.write JSON.pretty_generate(all_hash)
  end

  # Write to HTML table rows.
  output = []
  all_hash.each do |key1, val1|
    if val1
      val1.each do |key2, val2|
        output << "<tr><td><a href='#{key1}'>#{key1.partition('//').last}</a></td><td>#{key2}</td><td><a href='#{val2}'>#{val2}</a></td></tr>"
      end
    end
  end
  output
end

# Now read back to 'users.html'
def self.write_to_html(table_html)
  File.open(OUTPUT_FILE_HTML, 'w') do |fo|
    File.open(TEMPLATE_FILE_HTML, 'r') do |fi|
      out = fi.read.gsub('<!-- @USER_LIST -->', table_html.join("\n"))
      out = out.gsub('<!-- @TIME_STAMP -->', Time.now.strftime("%Y/%m/%d %H:%M GMT"))
      fo.puts out
    end
  end
end

################################################################################

# ~pfhawkins JSON list of all other tildes.
# If this has been updated let me know. Then I can manually add the new box.
def self.get_all_tildes
  string_json = open('http://tilde.club/~pfhawkins/othertildes.json').read
  JSON.parse(string_json).values.map do |i|
    i = i[0...-1] if i[-1] == '/'
    i = i.partition('//').last
  end
end
def self.check_for_new_boxes
  if get_all_tildes.length != 33
    puts '-- New Tilde Boxes!'
    puts 'http://tilde.club/~pfhawkins/othertildes.html'
  end
end

################################################################################

# Check each Tildebox to see if they have a '/tilde.json' file.
# I already know that 3 do, so let me know if that number changes.
#   https://club6.nl/tilde.json
#   http://ctrl-c.club/tilde.json
#   https://squiggle.city/tilde.json
def self.get_all_tilde_json

  # Read from the master list of Tilde URLs, and append '/tilde.json' to them.
  obj_json = JSON.parse( open(OUTPUT_FILE_JSON).read )
  urls_json = obj_json.keys.map { |i| i += '/tilde.json' }

  # Only select the URLs that can be parsed as JSON.
  urls_json.select do |item|
    begin
      JSON.parse( open(item).read )
      true
    rescue
      false
    end
  end
end

def self.check_for_new_desc_json
  tilde_desc_files = get_all_tilde_json
  if tilde_desc_files.length != 3
    puts '-- Tilde Description JSON files:'
    puts tilde_desc_files
    puts nil
  end
end

################################################################################

def self.tweet_user_diffs

  def greeting_message(plural = true)
    msg = []
    msg << "Hooray!"
    msg << "Hello!"
    msg << "Howdy, you!"
    msg << "Welcome, welcome!"
    msg << "Welcome to the Tildeverse!"
    msg << "So much love for you!"
    msg << "All is full of love!"
    msg << "Nice to meet you!"
    msg << "The beginning of a beautiful friendship!"
    msg << "You are just sensational!"
    msg << "A stranger is just a friend you haven't IRC'd with yet!"
    if plural
      msg << "Welcome new users!"
      msg << "New people! Whee!"
      msg << "Attention! The following people are cool:"
    else
      msg << "A new person! Hooray!"
      msg << "A brand new person!"
      msg << "Be lovely to this person!"
      msg << "It's my new best friend!"
      msg << "I love you already!"
    end
    msg.sample
  end

  ########################################

  def farewell_message(plural = true)
    msg = []
    msg << "A fond farewell."
    msg << "In loving memory."
    msg << "Gone, but not forgotten."
    msg << "Better to have loved and lost..."
    msg << "The time has come. Farewell."
    msg << "I loved what we accomplished."
    msg << "I already miss you."
    msg << "You'll always be adored."
    msg << "We'll always have what we had."
    msg << "Never forget."
    msg << "So it goes."
    msg << "That's all, folks."
    if plural
      msg << "Absent friends, here's to them."
    end
    msg.sample
  end

  ########################################

  # Compare old and new users list to find differences.
  json_old = File.read(OUTPUT_FILE_JSON_PREV)
  json_new = File.read(OUTPUT_FILE_JSON)
  old = JSON.parse(json_old)
  new = JSON.parse(json_new)
  list_append = []
  list_remove = []
  JsonCompare.get_diff(old, new)[:update].each do |diff|
    hash_append = diff[1][:append]
    if hash_append
      hash_append.each do |i|
        list_append << i[1].strip
      end
    end
    hash_remove = diff[1][:remove]
    if hash_remove
      hash_remove.each do |i|
        list_remove << i[1].strip
      end
    end
  end

  ########################################

  # list_append
  if !list_append.empty?
    tweet_array = [greeting_message(list_append.length != 1)]
    tweet_array += list_append.map { |i| "++ " + i }
    tweetable_array = Tweeter::split_array_to_tweets(tweet_array)
    Tweeter::tweet_series(TWITTER_ACCOUNT, tweetable_array)
  end

  # list_remove
  if !list_remove.empty?
    tweet_array = [farewell_message(list_remove.length != 1)]
    tweet_array += list_remove.map { |i| "-- " + i }
    tweetable_array = Tweeter::split_array_to_tweets(tweet_array)
    Tweeter::tweet_series(TWITTER_ACCOUNT, tweetable_array)
  end
end

################################################################################

def self.run_all
  write_to_html(output_to_files) if WRITE_TO_FILES
  check_for_new_boxes if CHECK_FOR_NEW_BOXES
  check_for_new_desc_json if CHECK_FOR_NEW_DESC_JSON
  tweet_user_diffs if TWEET_USER_DIFFS
end

################################################################################

end

################################################################################

Tildeverse.run_all

################################################################################

__END__

# 2016/08/??  New Tildebox: https://backtick.town/

# https://backtick.town/~kc/
# https://backtick.town/~j/
# https://backtick.town/~nickolas360/

