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
# 2014/12/22  Initial. Scrapes all Tildeboxes from the master list:
#             http://tilde.club/~pfhawkins/othertildes.html
# 2014/12/28  Add JSON user list: protocol.club/~insom/protocol.24h.json
# 2015/01/03  New Tildebox: club6.nl
#             New Tildebox: losangeles.pablo.xyz
# 2015/01/04  Add HTML user list: club6.nl/index.html
# 2015/01/05  Include http/https protocol info in JSON
#             Add oldbsd.club to JSON, even though there's no user info
# 2015/01/06  Check each Tildebox to see if they have a '/tilde.json' file
#             Add JSON user list: club6.nl/tilde.json
#             Add JSON user list: squiggle.city/tilde.json
#             Add JSON user list: yester.host/tilde.json
# 2015/01/08  Create backup of HTML and JSON files so can revert if necessary
# 2015/01/15  Add HTML user list: losangeles.pablo.xyz/index.html
# 2015/01/19  Fix HTML user list: noiseandsignal.com/index.html
# 2015/03/05  RIP: drawbridge.club (merged into tilde.town)
#             RIP: germantil.de
#             RIP: noiseandsignal.com
# 2015/06/13  Add class TildeConnection for connection error handling
#               We will now be able to schedule this script in cron
#               Also can now determine the exact date of future site 404s
#             RIP: drawbridge.club
#             RIP: losangeles.pablo.xyz
#             RIP: sunburnt.country
#             RIP: tilde.center
#             RIP: tilde.city
#             RIP: tilde.farm
#             RIP: yester.host
# 2015/08/09  RIP: catbeard.city
# 2015/10/05  RIP: bleepbloop.club
# 2015/10/11  RIP: tilde.camp
# 2015/10/13  RIP: hypertext.website
# 2015/11/13  Add error handling to method check_for_new_desc_json
#             Add JSON user list: ctrl-c.club/tilde.json
# 2015/11/17  New Tildebox: perispomeni.club
# 2016/01/13  Fix problem with using JSON.parse on strings containing tabs
#             squiggle.city is now HTTPS, not HTTP
#             RIP: club6.nl
# 2016/02/04  RIP: matilde.club
# 2016/02/23  RIP: totallynuclear.club
# 2016/02/24  RIP: tilde.red
# 2016/02/26  Added Twitter integration
# 2016/08/05  tilde.town JSON is incomplete, so merge with index.html user list
# 2016/08/10  New Tildebox: spookyscary.science
# 2016/08/14  RIP: retronet.net
#             Back: tilde.red
#             tilde.town now using https
# 2016/09/12  RIP: cybyte.club
#             New Tildebox: botb.club
#             Use 'Net::HTTP.get URI(url)' instead of 'open-uri'
#               This should fix certain HTTPS errors
#             Fix string encoding issues. Should now all be in 'UTF-8'
################################################################################

require 'net/http'
require 'net/https'
require 'open-uri'
require 'json'
#require 'json-compare'

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

TEMPLATE_FILE_HTML    = File.dirname(__FILE__) +'/users_template.html'
OUTPUT_FILE_HTML      = File.dirname(__FILE__) +'/users.html'
OUTPUT_FILE_JSON      = File.dirname(__FILE__) +'/users.json'
OUTPUT_FILE_JSON_PREV = File.dirname(__FILE__) +'/users_prev.json'

WRITE_TO_FILES          = true   # This is necessary.
CHECK_FOR_NEW_BOXES     = false  # This is fast.
CHECK_FOR_NEW_DESC_JSON = false  # This is slow.
TRY_KNOWN_DEAD_SITES    = false  # This is pointless.
TWEET_USER_DIFFS        = false  # This is broken.

################################################################################

# For dev testing purposes only.
def puts_hash(input_hash)
  input_hash.each do |key, array|
    puts "#{'%16.16s' % key} | #{array}"
  end
end

# Sort a hash by keys. Really just to make the JSON file more human-readable.
def sort_hash_by_keys(in_hash)
  output = {}
  in_hash.keys.sort.each { |i| output[i] = in_hash[i] }
  output
end

# Patch the String class. Gotta love Ruby.
class String
  def remove_trailing_slash
    self[-1] == '/' ? self[0...-1] : self
  end

  # Get the string between the first and second occurances of a char.
  # Return nil if invalid or char.length > 1
  def first_between_two_chars(char = '"')
    between = scan(/#{char}([^#{char}]*)#{char}/).first
    between.join if between
  end
end

################################################################################

# Connection to a tilde box.
# Begin/rescue blocks for connection errors to the user list and root URL.
# Gives a sensible error string if either URL is offline.
# After #test_connection is called, @user_list contains raw source user list,
#   unless the connection failed (then it's nil).
class TildeConnection
  attr_accessor :name
  attr_accessor :root_url
  attr_accessor :list_url
  attr_reader   :error
  attr_reader   :error_message
  attr_reader   :root_url_connection
  attr_reader   :list_url_connection
  attr_reader   :user_list

  def initialize(name)
    @name = name
  end

  def test_connection

    # Test the user list page.
#    begin
      uri = URI(@list_url)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri
        @user_list = http.request(request).body
      end
      if @user_list.encoding.name != 'UTF-8'
        @user_list.force_encoding('UTF-8').encode
      end
      @list_url_connection = true
      @root_url_connection = true
  #  rescue
      @user_list = nil
      @list_url_connection = false
  #  end

    # If that failed, test the root page.
    if @list_url_connection == false
      begin
        open(@root_url)
        @root_url_connection = true
      rescue
        @root_url_connection = false
      end
    end

    # Set error message.
    if not @list_url_connection
      @error = true
      @error_message = "#{@name} user list is currently offline:  #{@list_url}"
    end
    if not @root_url_connection
      @error = true
      @error_message = "#{@name} is currently offline:  #{@root_url}"
    end

    # Return user list as the return value, if it didn't fail. Else return nil.
    @user_list
  end
end

################################################################################

# These are the only lines on the page that begin with '<li>'
# 2016/02/23  RIP
def read_totallynuclear_club
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('totallynuclear.club')
  tilde_connection.root_url = 'http://totallynuclear.club/'
  tilde_connection.list_url = 'http://totallynuclear.club/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/^<li>/)
        url = i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_totallynuclear_club)

################################################################################

# These are the only lines on the page that begin with '<li>'
def read_palvelin_club
  output = {}

  tilde_connection = TildeConnection.new('palvelin.club')
  tilde_connection.root_url = 'http://palvelin.club/'
  tilde_connection.list_url = 'http://palvelin.club/users.html'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else

    # This is very hacky, but it fixes the string encoding problem.
    user_list[89..-1].split("\n").each do |i|
      if i.match(/^<li>/)
        url = 'http://palvelin.club' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_palvelin_club)

################################################################################

# These are the only lines on the page that begin with '<li>'
# 2015/06/13  RIP
def read_tilde_center
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('tilde.center')
  tilde_connection.root_url = 'https://tilde.center/'
  tilde_connection.list_url = 'https://tilde.center/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/^<li/)
        i = i.partition('a href').last.strip
        url = 'https://tilde.center' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_tilde_center)

################################################################################

# These are the lines on the page that begin with '<li>'
# But only after the line '<div class="row" id="members">'
#   and before '</ul>'
#
# 2015/03/05  RIP, I guess?
# http://noiseandsignal.com/~tyler/ still exists though...
# 2015/10/26  RIP
def read_noiseandsignal_com
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('noiseandsignal.com')
  tilde_connection.root_url = 'http://noiseandsignal.com/'
  tilde_connection.list_url = 'http://noiseandsignal.com/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    membersFound = false
    user_list.split("\n").each do |i|
      membersFound = true  if i.match(/<div class="row" id="members">/)
      membersFound = false if i.match(/<\/ul>/)
      if membersFound and i.match(/<li/)
        url = 'http://noiseandsignal.com' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_noiseandsignal_com)

################################################################################

# Out of date as of 2014/12/22
# These are the lines on the page that begin with '<li>'
# But only after the line '<ol class="user-list">'
#   and before '<h1>What can I do?</h1>'
def read_ctrl_c_club_1
  output = {}
  membersFound = false
  begin
    open('http://ctrl-c.club/').read.split("\n").each do |i|
      membersFound = true  if i.strip == '<ol class="user-list">'
      membersFound = false if i.strip == '<h1>What can I do?</h1>'
      if membersFound and i.match(/<li><a href=/)
        i = i.partition('a href').last.strip
        url = 'http://ctrl-c.club' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
  rescue
  end
  puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  sort_hash_by_keys(output)
end
#puts_hash(read_ctrl_c_club_1)

########################################

# Current as of 2014/12/22
# This is not newline based anymore, so need to do other stuff.
# Damn, this is really tricky now. Not every user has a page...
def read_ctrl_c_club_2
  output = {}

  tilde_connection = TildeConnection.new('ctrl-c.club')
  tilde_connection.root_url = 'http://ctrl-c.club/'
  tilde_connection.list_url = 'http://ctrl-c.club/who.html'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else

    user_list.split("\n").each do |i|
      if i.match(/li><li><a href/)
        i.split('</li><li>').each do |j|
          j = j.gsub('<li>','').strip

          # Some of these are just the user, e.g. '~ubercow'
          if j[0] == '~'
            name = j[1..-1]
            url = 'http://ctrl-c.club/' + j

          # But some are normal, e.g. '<a href="/~jovan">~jovan</a>'
          else
            url = 'http://ctrl-c.club' + j.first_between_two_chars('"')
            url = url.remove_trailing_slash
            name = url.partition('~').last.strip
          end
          output[name] = url
        end
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_ctrl_c_club_2)

########################################

# Current as of 2015/11/13
def read_ctrl_c_club
  output = {}

  tilde_connection = TildeConnection.new('ctrl-c.club')
  tilde_connection.root_url = 'http://ctrl-c.club/'
  tilde_connection.list_url = 'http://ctrl-c.club/tilde.json'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    parsed = JSON.parse( user_list.gsub("\t",'') )
    parsed['users'].each do |i|
      name = i['username']
      url = 'http://ctrl-c.club/~' + name
      output[name] = url
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_ctrl_c_club)

################################################################################

# These are the only lines on the page that begin with '<li>'
def read_tilde_club
  output = {}

  tilde_connection = TildeConnection.new('tilde.club')
  tilde_connection.root_url = 'http://tilde.club/'
  tilde_connection.list_url = 'http://tilde.club/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/^<li>/)
        url = 'http://tilde.club' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_tilde_club)

################################################################################

# 2016/08/05  JSON is incomplete, so merge with index.html user list

# A nice easy JSON format.
def read_tilde_town_json
  output = {}

  tilde_connection = TildeConnection.new('tilde.town')
  tilde_connection.root_url = 'http://tilde.town/'
  tilde_connection.list_url = 'http://tilde.town/~dan/users.json'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    parsed = JSON.parse( user_list.gsub("\t",'') )
    parsed.each do |i|
      name = i[0]
      url = i[1]['homepage'].sub('http://','https://')
      output[name] = url
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end

########################################

# These are the lines on the page that include 'a href'
# But only after the line '<sub>sorted by recent changes</sub>'
#   and before the closing '</ul>'
def read_tilde_town_index
  output = {}

  tilde_connection = TildeConnection.new('tilde.town')
  tilde_connection.root_url = 'https://tilde.town/'
  tilde_connection.list_url = 'https://tilde.town/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    membersFound = false
    user_list.split("\n").each do |i|
      membersFound = true  if i.match(/<sub>sorted by recent changes<\/sub>/)
      membersFound = false if i.match(/<\/ul>/)
      if membersFound and i.match(/a href/)
        url = i.first_between_two_chars('"')
        url = 'https://tilde.town' + url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end

########################################

def read_tilde_town
  json   = read_tilde_town_json
  index  = read_tilde_town_index
  merged = json.merge(index)
  sort_hash_by_keys(merged)
end
#puts_hash(read_tilde_town)

################################################################################

# These are the lines on the page that include '<li><a href'
def read_tildesare_cool
  output = {}

  tilde_connection = TildeConnection.new('tildesare.cool')
  tilde_connection.root_url = 'http://tildesare.cool/'
  tilde_connection.list_url = 'http://tildesare.cool/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href=/)
        i = i.partition('a href').last.strip
        url = i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_tildesare_cool)

################################################################################

# These are lines on the page that include '<li><a href', after the line that
#   matches '<p>Current users:</p>'
def read_hackers_cool
  output = {}

  tilde_connection = TildeConnection.new('hackers.cool')
  tilde_connection.root_url = 'http://hackers.cool/'
  tilde_connection.list_url = 'http://hackers.cool/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    membersFound = false
    user_list.split("\n").each do |i|
      membersFound = true if i.strip == '<p>Current users:</p>'
      if membersFound and i.match(/<li><a href/)
        url = i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_hackers_cool)

################################################################################

# These are the only lines on the page that include '<li><a href'
def read_tilde_works
  output = {}

  tilde_connection = TildeConnection.new('tilde.works')
  tilde_connection.root_url = 'http://tilde.works/'
  tilde_connection.list_url = 'http://tilde.works/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    membersFound = false
    user_list.split("\n").each do |i|
      membersFound = true  if i.strip == '<h2>users</h2>'
      membersFound = false if i.strip == '</ul>'
      if membersFound and i.match(/<li><a href/)
        url = i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_tilde_works)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2015/10/26  RIP
def read_hypertext_website
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('hypertext.website')
  tilde_connection.root_url = 'http://hypertext.website/'
  tilde_connection.list_url = 'http://hypertext.website/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = i.first_between_two_chars("'")
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_hypertext_website)

################################################################################

# These are the only lines on the page that include '<tr><td><a href'
def read_squiggle_city_html
  output = {}

  tilde_connection = TildeConnection.new('squiggle.city')
  tilde_connection.root_url = 'https://squiggle.city/'
  tilde_connection.list_url = 'https://squiggle.city/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<tr><td><a href/)
        url = 'https://squiggle.city' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.to_s.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_squiggle_city_html)

########################################

# JSON format. There's a NULL record at the end of the file though.
# Also, doesn't seem to include all users...
def read_squiggle_city_json
  output = {}

  tilde_connection = TildeConnection.new('squiggle.city')
  tilde_connection.root_url = 'https://squiggle.city/'
  tilde_connection.list_url = 'https://squiggle.city/tilde.json'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    parsed = JSON.parse( user_list )
    parsed['users'].each do |i|
      name = i['username']
      break if name == nil
      url = 'https://squiggle.city/~' + name
      output[name] = url
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_squiggle_city_json)

########################################

# The JSON doesn't include all the users.
# So group them together, sort and uniq.
def read_squiggle_city
  a = read_squiggle_city_html
  b = read_squiggle_city_json
  a.merge(b)
end
#puts_hash(read_squiggle_city)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2016/02/24  RIP
# 2016/08/14  Back!
def read_tilde_red
  output = {}

  tilde_connection = TildeConnection.new('tilde.red')
  tilde_connection.root_url = 'https://tilde.red/'
  tilde_connection.list_url = 'https://tilde.red/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = 'https:' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_tilde_red)

################################################################################

# Manually found 2 users, but no list.
# 2015/06/13  RIP
def read_tilde_city
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  output['twilde'] = 'http://tilde.city/~twilde'
  output['skk'] = 'http://tilde.city/~skk'
  sort_hash_by_keys(output)
end
#puts_hash(read_tilde_city)

################################################################################

# These are the only lines on the page that include '<li><a href'
def read_yester_host_html
  output = {}

  tilde_connection = TildeConnection.new('yester.host')
  tilde_connection.root_url = 'http://yester.host/'
  tilde_connection.list_url = 'http://yester.host/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_yester_host_html)

########################################

# JSON format. There's a NULL record at the end of the file though.
def read_yester_host_json
  output = {}

  tilde_connection = TildeConnection.new('yester.host')
  tilde_connection.root_url = 'http://yester.host/'
  tilde_connection.list_url = 'http://yester.host/tilde.json'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    parsed = JSON.parse( user_list )
    parsed['users'].each do |i|
      name = i['username']
      break if name == nil
      url = 'http://yester.host/~' + name
      output[name] = url
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_yester_host_json)
########################################

# 2015/06/13  RIP
def read_yester_host
  return {} unless TRY_KNOWN_DEAD_SITES
  read_yester_host_json
end
#puts_hash(read_yester_host)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2015/03/05  drawbridge.club merged into tilde.town
def read_drawbridge_club
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('drawbridge.club')
  tilde_connection.root_url = 'http://drawbridge.club/'
  tilde_connection.list_url = 'http://drawbridge.club/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = 'http://drawbridge.club' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_drawbridge_club)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2015/10/26  RIP
def read_tilde_camp
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('tilde.camp')
  tilde_connection.root_url = 'http://tilde.camp/'
  tilde_connection.list_url = 'http://tilde.camp/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = 'http://tilde.camp' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_tilde_camp)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2015/06/13  RIP
def read_tilde_farm
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('tilde.farm')
  tilde_connection.root_url = 'http://tilde.farm/'
  tilde_connection.list_url = 'http://tilde.farm/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = 'http://tilde.farm' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_tilde_farm)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2015/06/13  RIP
def read_rudimentarylathe_org
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('rudimentarylathe.org')
  tilde_connection.root_url = 'http://rudimentarylathe.org/'
  tilde_connection.list_url = 'http://rudimentarylathe.org/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = 'http://rudimentarylathe.org/' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_rudimentarylathe_org)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2016/09/03  RIP
def read_cybyte_club
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('cybyte.club')
  tilde_connection.root_url = 'http://cybyte.club/'
  tilde_connection.list_url = 'http://cybyte.club/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = 'http://cybyte.club' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_cybyte_club)

################################################################################

# A nice easy JSON format. Hooray!
# https://protocol.club/~insom/protocol.24h.json

# There's also HTML lists here:
# https://protocol.club/~silentbicycle/homepages.html
# https://protocol.club/~insom/protocol.24h.html
def read_protocol_club
  output = {}

  tilde_connection = TildeConnection.new('protocol.club')
  tilde_connection.root_url = 'https://protocol.club/'
  tilde_connection.list_url = 'http://protocol.club/~insom/protocol.24h.json'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    parsed = JSON.parse( user_list.gsub("\t",'') )
    parsed['pagelist'].each do |i|
      name = i['username']
      url = i['homepage'].remove_trailing_slash
      output[name] = url
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_protocol_club)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2016/08/14  RIP: retronet.net
def read_retronet_net
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('retronet.net')
  tilde_connection.root_url = 'http://retronet.net/'
  tilde_connection.list_url = 'http://retronet.net/users.html'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_retronet_net)

################################################################################

# Really easy, just read every line of the html.
# 2015/06/13  RIP
def read_sunburnt_country
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('sunburnt.country')
  tilde_connection.root_url = 'http://sunburnt.country/'
  tilde_connection.list_url = 'http://sunburnt.country/~tim/directory.html'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      url = i.first_between_two_chars('"')
      url = url.gsub('../','http://sunburnt.country/')
      name = url.partition('~').last.strip
      output[name] = url
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_sunburnt_country)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2015/03/05  RIP
def read_germantil_de
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('germantil.de')
  tilde_connection.root_url = 'http://germantil.de/'
  tilde_connection.list_url = 'http://germantil.de/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li><a href/)
        url = i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_germantil_de)

################################################################################

# This is straight from someone's ~user index.html.
# I'm betting this will be the first page to break.
# 2015/10/26  RIP
def read_bleepbloop_club
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('bleepbloop.club')
  tilde_connection.root_url = 'https://bleepbloop.club/'
  tilde_connection.list_url = 'https://bleepbloop.club/~eos/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li>/)
        url = 'https://bleepbloop.club' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_bleepbloop_club)

################################################################################

# These are lines on the page that include '<li><a href'
# But only between two other lines.
# 2015/10/26  RIP
def read_catbeard_city
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('catbeard.city')
  tilde_connection.root_url = 'http://catbeard.city/'
  tilde_connection.list_url = 'http://catbeard.city/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    membersFound = false
    user_list.split("\n").each do |i|
      membersFound = true  if i.match(/<p>Current inhabitants:</)
      membersFound = false if i.match(/<h2>Pages Changed In Last 24 Hours</)
      if membersFound and i.match(/<li><a href/)
        url = 'http://catbeard.city/' + i.first_between_two_chars("'")
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_catbeard_city)

################################################################################

# These are the only lines on the page that include '<a href'
def read_skylab_org
  output = {}

  tilde_connection = TildeConnection.new('skylab.org')
  tilde_connection.root_url = 'http://skylab.org/'
  tilde_connection.list_url = 'http://skylab.org/clique/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<a href/)
        url = 'http://skylab.org' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_skylab_org)

################################################################################

# These are the only lines on the page that include '<a href'
def read_riotgirl_club
  output = {}

  tilde_connection = TildeConnection.new('riotgirl.club')
  tilde_connection.root_url = 'http://riotgirl.club/'
  tilde_connection.list_url = 'http://riotgirl.club/~jspc/user_list.html'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<a href/)
        url = 'http://riotgirl.club' + i.first_between_two_chars("'")
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_riotgirl_club)

################################################################################

# A bit different, this one. They don't even use Tildes!
def read_remotes_club
  output = {}

  tilde_connection = TildeConnection.new('remotes.club')
  tilde_connection.root_url = 'https://www.remotes.club/'
  tilde_connection.list_url = 'https://www.remotes.club/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<li data-last-update/)
        i = i.partition('<span>').last.strip
        url = i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('.').first.sub('https://','')
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_remotes_club)

################################################################################

# This is not newline based, so need to do other stuff.
# 2016/02/04  RIP
def read_matilde_club
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('matilde.club')
  tilde_connection.root_url = 'http://matilde.club/'
  tilde_connection.list_url = 'http://matilde.club/~mikker/users.html'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/<ul><li>/)
        i.split('</li><li>').each do |j|
          url = 'http://matilde.club' + j.first_between_two_chars("'")
          url = url.remove_trailing_slash
          name = url.partition('~').last.strip
          output[name] = url
        end
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_matilde_club)

################################################################################

# Manually found 8 users, but no easily parsable list.
def read_pebble_ink
  output = {}
  %w{clach04 contolini elzilrac imt jovan ke7ofi phildini waste}.each do |i|
    output[i] = "http://pebble.ink/~#{i}"
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_pebble_ink)

################################################################################

# New box 2015/01/03
# A nice easy JSON format.
# 2016/01/13  RIP
def read_club6_nl
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('club6.nl')
  tilde_connection.root_url = 'https://club6.nl/'
  tilde_connection.list_url = 'https://club6.nl/tilde.json'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    parsed = JSON.parse( user_list )
    parsed['users'].each do |i|
      name = i['username']
      url = 'https://club6.nl/~' + name
      output[name] = url
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_club6_nl)

################################################################################

# 2015/01/03  New tildebox
# 2015/01/15  User list on index.html
# 2015/06/13  RIP
def read_losangeles_pablo_xyz
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  tilde_connection = TildeConnection.new('losangeles.pablo.xyz')
  tilde_connection.root_url = 'http://losangeles.pablo.xyz/'
  tilde_connection.list_url = 'http://losangeles.pablo.xyz/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    membersFound = false
    user_list.split("\n").each do |i|
      membersFound = true if i.match(/<p><b>Users</)
      if membersFound and i.match(/<li>/)
        i.split('<li').each do |j|
          j = j.strip.gsub('</li','')
          if j != ''
            name = j.first_between_two_chars('>')
            url = 'http://losangeles.pablo.xyz/~' + name
            output[name] = url
          end
        end
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_losangeles_pablo_xyz)

################################################################################

# 2015/11/17  New tildebox, user list on index.html
# These are the lines on the page that begin with '<li>'
# But only after the line '<h2>users</h2>'
#   and before '</ul>'
def read_perispomeni_club
  output = {}

  tilde_connection = TildeConnection.new('perispomeni.club')
  tilde_connection.root_url = 'http://perispomeni.club/'
  tilde_connection.list_url = 'http://perispomeni.club/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    membersFound = false
    user_list.split("\n").each do |i|
      membersFound = true  if i.match(/<h2>users<\/h2>/)
      membersFound = false if i.match(/<\/ul>/)
      if membersFound and i.match(/<li/)
        url = i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_perispomeni_club)

################################################################################

# New box 2016/08/10
def read_spookyscary_science
  output = {}

  tilde_connection = TildeConnection.new('spookyscary.science')
  tilde_connection.root_url = 'https://spookyscary.science/'
  tilde_connection.list_url = 'https://spookyscary.science/~'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/^<a href/)
        url = 'https://spookyscary.science' + i.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_spookyscary_science)

################################################################################

# New box 2016/09/12
# This one is weird. It doesn't like me scraping the index.html
# So I'm reading from a saved archive.is backup.
def read_botb_club
  output = {}

  tilde_connection = TildeConnection.new('botb.club')
  tilde_connection.root_url = 'https://botb.club/'
  tilde_connection.list_url = 'http://archive.is/kZ9cr'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/^<li style/)
        i.sub!('<li style="text-align:left;font-size:13pt;font-weight:normal;">','')
        url = 'https://botb.club' + i.first_between_two_chars('"')
        url = i.first_between_two_chars('"').sub('https://archive.is/o/kZ9cr/','https://')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = url
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_botb_club)

################################################################################

def output_to_files
  def read_all_to_hash
    userHash = {}
    userHash['https://bleepbloop.club'] = read_bleepbloop_club
    userHash['https://botb.club'] = read_botb_club
    userHash['http://catbeard.city'] = read_catbeard_city
    userHash['https://club6.nl'] = read_club6_nl
    userHash['http://ctrl-c.club'] = read_ctrl_c_club
    userHash['http://cybyte.club'] = read_cybyte_club
    userHash['http://drawbridge.club'] = read_drawbridge_club
    userHash['http://germantil.de'] = read_germantil_de
    userHash['http://hackers.cool'] = read_hackers_cool
    userHash['http://hypertext.website'] = read_hypertext_website
    userHash['http://losangeles.pablo.xyz'] = read_losangeles_pablo_xyz
    userHash['http://matilde.club'] = read_matilde_club
    userHash['http://noiseandsignal.com'] = read_noiseandsignal_com
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
  all_hash = read_all_to_hash

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
def write_to_html(table_html)
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
def get_all_tildes
  string_json = open('http://tilde.club/~pfhawkins/othertildes.json').read
  JSON.parse(string_json).values.map do |i|
    i = i[0...-1] if i[-1] == '/'
    i = i.partition('//').last
  end
end
def check_for_new_boxes
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
def get_all_tilde_json

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

def check_for_new_desc_json
  tilde_desc_files = get_all_tilde_json
  if tilde_desc_files.length != 3
    puts '-- Tilde Description JSON files:'
    puts tilde_desc_files
    puts nil
  end
end

################################################################################

def tweet_user_diffs

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

write_to_html(output_to_files) if WRITE_TO_FILES
check_for_new_boxes if CHECK_FOR_NEW_BOXES
check_for_new_desc_json if CHECK_FOR_NEW_DESC_JSON
tweet_user_diffs if TWEET_USER_DIFFS

################################################################################

__END__

# 2016/08/??  New Tildebox: https://backtick.town/

# https://backtick.town/~kc/
# https://backtick.town/~j/
# https://backtick.town/~nickolas360/

