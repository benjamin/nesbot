require 'core/plugin_sugar'

class PluginBase
  extend PluginSugar
  def_field :author, :version, :desc
  attr_reader :commands
  
  def initialize(bot)
    @bot = bot
    @commands = nil
  end
  
  def to_s
    "Author: #{author}<br/>Version: #{version}<br/>Desc: #{desc}"
  end
  
  def commands
    return @commands unless @commands.nil?

    @commands = []
    self.local_methods.each do |m|      
      s = m.split("_")
      if s[0] == 'admin' || s[0] == 'public'
        type = s.shift
        @commands.push({:type => type, :name => s.join("_")})
      end
    end
    
    @commands
  end
  
  #This is called when the bot hears a message in a blast group
  #that isn't directed to it
  def on_non_directed_message(message, speaker, buddy, command_executed)
    #at this stage we do nothing...
  end
  
  #This is called when the bot hears a message in a blast group
  #that is directed to it
  def on_directed_message(message, speaker, buddy, command_executed)
    #at this stage we do nothing...
  end
  
  #This is called when the bot is sent a message directly
  def on_private_message(message, buddy, command_executed)
    #at this stage we do nothing...
  end
end