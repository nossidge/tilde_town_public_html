#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Monkey patch the String class.
################################################################################

module Tildeverse
  module CoreExtensions
    module String

      # Remove trailing slash if there is one.
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
  end
end

################################################################################

class String
  include Tildeverse::CoreExtensions::String
end

################################################################################
