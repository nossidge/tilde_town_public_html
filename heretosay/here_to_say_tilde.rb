#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# here_to_say_tilde.rb
# Read the IRC logs into a database. Find the rhyme scheme of the last word.
# Find all lines that rhyme with 'say'
################################################################################
# To download the current irc log from TildeTown:
#   scp nossidge@tilde.town:~jumblesale/irc/log jsale_irc_log_`date +%Y%m%d`.txt
################################################################################

require 'ruby_rhymes'
require 'sqlite3'

DB_FILE = 'test.db'

################################################################################

class String
  def numeric?
    Float(self) != nil rescue false
  end
end

################################################################################

def puts_rhyme(word)
  puts "#{word}    #{word.to_phrase.rhymes.keys.join('|')}"
end

def get_rhyme(word)
  word.to_phrase.rhymes.keys.join('|')
end

# Make a string of rhyme 
# "rhyme = 'R' OR rhyme = '7R' OR rhyme = '*R'"
def big_sql_rhyme_string
  rhymes = %w(day days fail fails fade fades fate fates
              fail fails failed save saves saved cage
              caged crazed rain rains rained)
  array_rhymes = rhymes.map { |i| get_rhyme(i) }
  array_rhymes.map { |i| "rhyme = '#{i}'" }.join(' OR ')
end

################################################################################

# Read the file in.
def chat_log_to_sql_import_format(file_to_read, file_to_write)
  File.open(file_to_write, 'w') do |fo|
    File.open(file_to_read, 'r').each_line do |line|
      array = line.gsub('"', '""').delete("\n").split("\t")
      if array
        if array.length >= 3
          
          # Human readable variable names.
          time_stamp = array[0]
          user = array[1]
          chat_text = array[2..-1].join("\t")
          
          # Sanitise the users a wee bit.
          user = 'jumblesale' if user == 'jumblesal'
          user = 'brighty' if user == 'brightclo'
          
          # Get rhymes using the ruby_rhymes gem.
          begin
            if chat_text[-1].numeric? || [']',')',':'].include?(chat_text[-1])
              rhyme = ''
            else
              rhyme = chat_text.to_phrase.rhymes
              rhyme = rhyme.keys.join('|').gsub('"', '""')
            end
          rescue
            rhyme = ''
          end
          
          fo.puts "#{time_stamp}\t\"#{user}\"\t\"#{chat_text}\"\t\"#{rhyme}\""
        end
      end
    end
  end
end

################################################################################

def create_database
  
  #Delete any existing database.
  File.delete(DB_FILE) rescue nil
  
  # Write SQL and SQLite instructions to temp file, import to database, delete temp file.
  sql = %Q~CREATE TABLE IF NOT EXISTS tblFullLogs (timeStamp DATETIME, userName TEXT, chatText TEXT, rhyme TEXT) ;
    .separator "\t"
    .import sql_import.txt tblFullLogs
  ~.gsub('    ','')
  File.open('TEMP.sql','w') { |fo| fo.write sql }
  `sqlite3 #{DB_FILE} < TEMP.sql`
  File.delete('TEMP.sql')
end

################################################################################

def get_say_rhymes
  SQLite3::Database.new(DB_FILE) do |db|
    sql_string = "SELECT userName, chatText FROM tblFullLogs WHERE #{big_sql_rhyme_string} ;"
    db.execute(sql_string) do |row|
      user = row[0]
      text = row[1]
      syll = text.to_phrase.syllables
      if syll >= 8 && syll <= 10
        phrase = "My name's #{user} and I'm here to say<br><br>#{text.capitalize}\n"
        phrase.gsub!("'","&#39;")
        phrase.gsub!('"',"&#34;")
        puts phrase
      end
    end
  end
end

################################################################################

# Run the methods. Comment out the ones not needed.

#chat_log_to_sql_import_format('jsale_irc_log_20160707.txt','sql_import.txt')
#create_database
#get_say_rhymes

################################################################################

