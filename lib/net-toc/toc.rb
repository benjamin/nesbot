# A small library that connects to AOL Instant Messenger using the TOC v2.0 protocol.
#
# Author::    Ian Henderson (mailto:ian@ianhenderson.org)
# Copyright:: Copyright (c) 2006 Ian Henderson
# License::   revised BSD license (http://www.opensource.org/licenses/bsd-license.php)
# Version::   0.2
# 
# See Net::TOC for documentation.


require 'socket'

module Net
  # == Overview
  # === Opening a Connection
  # Pass Net::Toc.new your screenname and password to create a new connection.
  # It will return a Client object, which is used to communicate with the server.
  #
  #  client = Net::TOC.new("screenname", "p455w0rd")
  #
  # To actually connect, use Client#connect.
  #
  #  client.connect
  #
  # If your program uses an input loop (e.g., reading from stdin), you can start it here.
  # Otherwise, you must use Client#wait to prevent the program from exiting immediately.
  #
  #  client.wait
  #
  # === Opening a Connection - The Shortcut
  # If your program only sends IMs in response to received IMs, you can save yourself some code.
  # Net::TOC.new takes an optional block argument, to be called each time a message arrives (it is passed to Client#on_im).
  # Client#connect and Client#wait are automatically called.
  #
  #  Net::TOC.new("screenname", "p455w0rd") do | message, buddy |
  #    # handle the im
  #  end
  #
  # === Receiving Events
  # Client supports two kinds of event handlers: Client#on_im and Client#on_error.
  #
  # The given block will be called every time the event occurs.
  #  client.on_im do | message, buddy |
  #    puts "#{buddy.screen_name}: #{message}"
  #  end
  #  client.on_error do | error |
  #    puts "!! #{error}"
  #  end
  #
  # You can also receive events using Buddy#on_status.
  # Pass it any number of statuses (e.g., :away, :offline, :available, :idle) and a block;
  # the block will be called each time the buddy's status changes to one of the statuses.
  #
  #  friend = client.buddy_list.buddy_named("friend")
  #  friend.on_status(:available) do
  #    friend.send_im "Hi!"
  #  end
  #  friend.on_status(:idle, :away) do
  #    friend.send_im "Bye!"
  #  end
  #
  # === Sending IMs
  # To send an instant message, call Buddy#send_im.
  #
  #  friend.send_im "Hello, #{friend.screen_name}!"
  #
  # === Status Changes
  # You can modify your state using these Client methods: Client#go_away, Client#come_back, and Client#idle_time=.
  #
  #  client.go_away "Away"
  #  client.idle_time = 600 # ten minutes
  #  client.come_back
  #  client.idle_time = 0 # stop being idle
  #
  # It is not necessary to call Client#idle_time= continuously; the server will automatically keep track.
  #
  # == Examples
  # === Simple Bot
  # This bot lets you run ruby commands remotely, but only if your screenname is in the authorized list.
  #
  #  require 'net/toc'
  #  authorized = ["admin_screenname"]
  #  Net::TOC.new("screenname", "p455w0rd") do | message, buddy |
  #    if authorized.member? buddy.screen_name
  #      begin
  #        result = eval(message.chomp.gsub(/<[^>]+>/,"")) # remove html formatting
  #        buddy.send_im result.to_s if result.respond_to? :to_s
  #      rescue Exception => e
  #        buddy.send_im "#{e.class}: #{e}"
  #      end
  #    end
  #  end
  # === (Slightly) More Complicated and Contrived Bot
  # If you message this bot when you're available, you get a greeting and the date you logged in.
  # If you message it when you're away, you get scolded, and then pestered each time you become available.
  #
  #  require 'net/toc'
  #  client = Net::TOC.new("screenname", "p455w0rd")
  #  client.on_error do | error |
  #    admin = client.buddy_list.buddy_named("admin_screenname")
  #    admin.send_im("Error: #{error}")
  #  end
  #  client.on_im do | message, buddy, auto_response |
  #    return if auto_response
  #    if buddy.available?
  #      buddy.send_im("Hello, #{buddy.screen_name}. You have been logged in since #{buddy.last_signon}.")
  #    else
  #      buddy.send_im("Liar!")
  #      buddy.on_status(:available) { buddy.send_im("Welcome back, liar.") }
  #    end
  #  end
  #  client.connect
  #  client.wait
  # === Simple Interactive Client
  # Use screenname<<message to send message.
  # <<message sends message to the last buddy you messaged.
  # When somebody sends you a message, it is displayed as screenname>>message.
  #
  #  require 'net/toc'
  #  print "screen name: "
  #  screen_name = gets.chomp
  #  print "password: "
  #  password = gets.chomp
  #  
  #  client = Net::TOC.new(screen_name, password)
  #  
  #  client.on_im do | message, buddy |
  #    puts "#{buddy}>>#{message}"
  #  end
  #  
  #  client.connect
  #  
  #  puts "connected"
  #  
  #  last_buddy = ""
  #  loop do
  #    buddy_name, message = *gets.chomp.split("<<",2)
  #
  #    buddy_name = last_buddy if buddy_name == ""
  #
  #    unless buddy_name.nil? or message.nil?
  #      last_buddy = buddy_name 
  #      client.buddy_list.buddy_named(buddy_name).send_im(message)
  #    end
  #  end
  module TOC
    class CommunicationError < RuntimeError # :nodoc:
    end
    
    # Converts a screen name into its canonical form - lowercase, with no spaces.
    def format_screen_name(screen_name)
      screen_name.downcase.gsub(/\s+/, '').gsub('[', '\[').gsub(']', '\]')
    end
    
    # Escapes a message so it doesn't confuse the server. You should never have to call this directly.
    def format_message(message) # :nodoc:
      msg = message.gsub(/(\r|\n|\r\n)/, '<br>')
      msg.gsub(/[{}\\"]/, "\\\\\\0") # oh dear
    end

    # Creates a new Client. See the Client.new method for details.
    def self.new(screen_name, password, &optional_block) # :yields: message, buddy, auto_response, client
      Client.new(screen_name, password, &optional_block)
    end
    
    Debug = false # :nodoc:
    
    ErrorCode = {
      901 => "<param> is not available.",
      902 => "Warning <param> is not allowed.",
      903 => "Message dropped; you are exceeding the server speed limit",
      980 => "Incorrect screen name or password.",
      981 => "The service is temporarily unavailable.",
      982 => "Your warning level is too high to sign on.",
      983 => "You have been connecting and disconnecting too frequently. Wait 10 minutes and try again.",
      989 => "An unknown error has occurred in the signon process."
    }
  end
  
  require 'lib/net-toc/buddy.rb'
  require 'lib/net-toc/buddy_list.rb'
  require 'lib/net-toc/client.rb'
  require 'lib/net-toc/connection.rb'
end
