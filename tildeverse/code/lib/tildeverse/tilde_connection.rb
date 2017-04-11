#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################
# Connection to a tilde box.
# Begin/rescue blocks for connection errors to the user list and root URL.
# Gives a sensible error string if either URL is offline.
# After #test_connection is called, @user_list contains raw source user list,
#   unless the connection failed (then it's nil).
################################################################################

module Tildeverse
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
end

################################################################################
