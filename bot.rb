require 'lib/net-toc/toc'
require 'core/plugin_system'
require 'core/core_extensions'
require 'config'

#The bot class
class Bot
  def initialize
    Plugins.bot = self
    load_plugins
    @quit = false
  end
  
  def my_names
    @my_names ||= [BotConfig::Nicknames, BotConfig::Name].flatten
  end
  
  def load_plugins
    puts "Loading all plugins....."
    Plugins.clear_registered
    Plugins.clear_commands
    Dir["#{BotConfig::PluginDir}/*.rb"].each{ |x| load x }
    puts "Plugins Loaded"
  end

  def quit
    @quit = true
  end

  def send_im_to(username, message)
     @client.buddy_list.buddy_named(username).send_im(message)
  end
  
  def send_exception_to_admins(e)
    BotConfig::AdminUsers.each do |username|
      send_im_to(username, 'Hi, an exception occurred:')
      send_im_to(username, e.inspect)
      send_im_to(username, e.backtrace.join("<br/>"))
    end
  end

  def start
    puts "Starting up..."
    @client = Net::TOC.new(BotConfig::Name, BotConfig::Password)

    @client.on_im do |message, buddy|
      command_executed = false
      final_message, speaker, command_name, arguments = parse_message(message, buddy)
      
      if speaker
        speaker = @client.buddy_list.buddy_named(speaker)
      else
        speaker = buddy
      end  
            
      #Command dispatch
      if command_name
        command = Plugins.commands[command_name]
        if command && speaker_can_execute_command(command, speaker.screen_name)
          plugin = Plugins.registered[command[:plugin_name]]
          plugin.send("#{command[:type]}_#{command_name}", {:buddy => buddy, :speaker => speaker, :cmd_args => arguments, :message => final_message })
          command_executed = true
        end
      end
      
      #Plugin Callbacks
      Plugins.registered.each do |name, instance|
        if buddy.screen_name == speaker.screen_name
          #We got a private message
          instance.send(:on_private_message, final_message, buddy, command_executed)
        elsif command_name
          #It's a directed message in a blast group (most likely a command)
          instance.send(:on_directed_message, final_message, speaker, buddy, command_executed)
        else
          #it's a blast group message not directed at us
          instance.send(:on_non_directed_message, final_message, speaker, buddy, command_executed)
        end
      end
    end
    
    
    @client.connect
    @client.wait 3
    puts 'Bot Started'
    
    while !@quit
      begin
        sleep 1
      rescue Exception => e
        send_exception_to_admins(e)
      end
    end
    
    puts "Bot finished"
    @client.disconnect
  end

private
  def speaker_can_execute_command(command, speaker)
    command[:type] == "public" || BotConfig::AdminUsers.include?(speaker)
  end

  def parse_message(message, buddy)
    #Strip HTML
    message = message.gsub(/<\/?[^>]*>/, "")

    #If it's a blast group, lets find the actual sender of the message
    if buddy.screen_name.match(/^\[.+?\]$/) #Check the buddy name is in the form: [buddy_name]
      speaker = message.match(/^\((.+)\)/)[1] #Match the speaker
    else
      speaker = nil
    end

    #Split the message into arguments
    parts = message.split(" ")

    #if it was sent to a blast group
    if speaker
      parts.shift
      #If the message was directed to me, then I have a command
      if parts[0].downcase == BotConfig::Name || BotConfig::Nicknames.include?(parts[0].downcase)
        parts.shift
        command = parts[0]
        arguments = parts[1, parts.size]
      else
        command = nil
        arguments = []
      end
    else
      #The message was directly sent to me, so it's a command
      command = parts[0]
      arguments = parts[1, parts.size]
    end
    
    final_message = parts.join(" ")
    
    return final_message, speaker, command, arguments
  end
end

#Main
bot = Bot.new
bot.start