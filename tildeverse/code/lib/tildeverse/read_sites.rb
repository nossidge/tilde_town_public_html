#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Lots of copy-pasting going on here. Each tilde is in a separate function.
#   I figured it was best to do it this way as no two Tildes are the same,
#   scraping wise. It wouldn't make sense to try to work out commonalities.
################################################################################

require 'json'

require_relative 'core_extensions/string.rb'
require_relative 'tilde_connection.rb'
require_relative 'misc.rb'

################################################################################

module Tildeverse

################################################################################

# These are the only lines on the page that begin with '<li>'
# 2016/02/23  RIP
def self.read_totallynuclear_club
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
def self.read_palvelin_club
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
def self.read_tilde_center
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
def self.read_noiseandsignal_com
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
def self.read_ctrl_c_club_1
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
def self.read_ctrl_c_club_2
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
def self.read_ctrl_c_club
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
def self.read_tilde_club
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
def self.read_tilde_town_json
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
def self.read_tilde_town_index
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

def self.read_tilde_town
  json   = read_tilde_town_json
  index  = read_tilde_town_index
  merged = json.merge(index)
  sort_hash_by_keys(merged)
end
#puts_hash(read_tilde_town)

################################################################################

# These are the lines on the page that include '<li><a href'
def self.read_tildesare_cool
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
def self.read_hackers_cool
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
def self.read_tilde_works
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
def self.read_hypertext_website
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
def self.read_squiggle_city_html
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
def self.read_squiggle_city_json
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
def self.read_squiggle_city
  a = read_squiggle_city_html
  b = read_squiggle_city_json
  a.merge(b)
end
#puts_hash(read_squiggle_city)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2016/02/24  RIP
# 2016/08/14  Back!
# 2017/04/11  RIP again
def self.read_tilde_red
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

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
def self.read_tilde_city
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

  output['twilde'] = 'http://tilde.city/~twilde'
  output['skk'] = 'http://tilde.city/~skk'
  sort_hash_by_keys(output)
end
#puts_hash(read_tilde_city)

################################################################################

# These are the only lines on the page that include '<li><a href'
def self.read_yester_host_html
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
def self.read_yester_host_json
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
def self.read_yester_host
  return {} unless TRY_KNOWN_DEAD_SITES
  read_yester_host_json
end
#puts_hash(read_yester_host)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2015/03/05  drawbridge.club merged into tilde.town
def self.read_drawbridge_club
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
def self.read_tilde_camp
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
def self.read_tilde_farm
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
def self.read_rudimentarylathe_org
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
def self.read_cybyte_club
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

# A few lists to choose from here:
# https://protocol.club/~insom/protocol.24h.json
# http://protocol.club/~silentbicycle/homepages.html
# http://protocol.club/~insom/protocol.24h.html

# 201x/xx/xx  Use https://protocol.club/~insom/protocol.24h.json
# 2017/04/11  Use http://protocol.club/~insom/protocol.24h.html
#             Also, the https has expired, do use http.
def self.read_protocol_club
  output = {}

  tilde_connection = TildeConnection.new('protocol.club')
  tilde_connection.root_url = 'http://protocol.club/'
  tilde_connection.list_url = 'http://protocol.club/~insom/protocol.24h.html'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.match(/^<li>/)
        url = i.sub('class="homepage-link"', '')
        url = url.first_between_two_chars('"')
        url = url.remove_trailing_slash
        name = url.partition('~').last.strip
        output[name] = tilde_connection.root_url + '~' + name
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_protocol_club)

################################################################################

# These are the only lines on the page that include '<li><a href'
# 2016/08/14  RIP: retronet.net
def self.read_retronet_net
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
def self.read_sunburnt_country
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
def self.read_germantil_de
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
def self.read_bleepbloop_club
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
def self.read_catbeard_city
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
def self.read_skylab_org
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
def self.read_riotgirl_club
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
def self.read_remotes_club
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
def self.read_matilde_club
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
def self.read_pebble_ink
  output = {}
  %w{clach04 contolini elzilrac imt jovan ke7ofi phildini waste}.each do |i|
    output[i] = "http://pebble.ink/~#{i}"
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_pebble_ink)

################################################################################

# 2015/01/03  New box, a nice easy JSON format.
# 2016/01/13  RIP
def self.read_club6_nl
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
def self.read_losangeles_pablo_xyz
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
def self.read_perispomeni_club
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

# 2016/08/10  New box
# 2017/11/04  Okay, something weird is going on here. Every page but the index
#             reverts to root. I guess consider it dead?
#             Alright, for now just use cached users. But keep a watch on it.
def self.read_spookyscary_science_live
  output = {}
  return output unless TRY_KNOWN_DEAD_SITES

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
def self.read_spookyscary_science
  output = {}
  %w{_vax aerandir arthursucks deuslapis
    drip roob spiff sternalrub wanderingmind}.each do |i|
    output[i] = "https://spookyscary.science/~#{i}"
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_spookyscary_science)

################################################################################

# 2016/09/12  New box
# This one is weird. It doesn't like me scraping the index.html
# So I'm reading from a saved archive.is backup.
def self.read_botb_club
  output = {}
#  return output unless TRY_KNOWN_DEAD_SITES

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

# 2017/04/11  New box, user list on index.html
def self.read_crime_team
  output = {}

  tilde_connection = TildeConnection.new('crime.team')
  tilde_connection.root_url = 'https://crime.team/'
  tilde_connection.list_url = 'https://crime.team/'
  user_list = tilde_connection.test_connection
  if tilde_connection.error
    puts tilde_connection.error_message

  else
    user_list.split("\n").each do |i|
      if i.strip.match(/^<li>/)
        url = i.first_between_two_chars('"')
        name = url.partition('~').last.strip
        output[name] = tilde_connection.root_url + '~' + name
      end
    end
    puts "ERROR: Empty hash in method: #{__method__}" if output.length == 0
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_crime_team)

################################################################################

# 2017/04/11  New box
# Manually found 8 users, but no list.
def self.read_backtick_town
  output = {}
  %w{alyssa j jay nk kc nickolas360 nix tb10}.each do |i|
    output[i] = "https://backtick.town/~#{i}"
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_backtick_town)

################################################################################

# Manually found 2 users, but no list.
def self.read_ofmanytrades_com
  output = {}
  %w{ajroach42 noah}.each do |i|
    output[i] = "https://ofmanytrades.com/~#{i}"
  end
  sort_hash_by_keys(output)
end
#puts_hash(read_ofmanytrades_com)

################################################################################

end

################################################################################
