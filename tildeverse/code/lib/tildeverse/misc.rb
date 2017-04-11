#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Miscellaneous methods.
################################################################################

module Tildeverse
#  module Misc

    # For dev testing purposes only.
    def self.puts_hash(input_hash)
      input_hash.each do |key, array|
        puts "#{'%16.16s' % key} | #{array}"
      end
    end

    # Sort a hash by keys. Really just to make the JSON file more human-readable.
    def self.sort_hash_by_keys(in_hash)
      output = {}
      in_hash.keys.sort.each { |i| output[i] = in_hash[i] }
      output
    end

#  end
end

################################################################################
