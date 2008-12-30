require 'core/plugin_base'

class Plugins
  @registered = {}
  @commands = {}
  @bot = nil
  class << self
    attr_reader :registered
    attr_reader :commands
    attr_accessor :bot
    private :new
  end

  def self.clear_registered
    @registered = {}
  end
  
  def self.clear_commands
    @commands = {}
  end
  
  def self.unregister_plugin(name)
    plugin = @registered[name]

    #Remove the plugins commands
    plugin.commands.each { |c| @commands.delete(c[:name]) }
    
    #Remove the plugin registration
    @registered.delete(name)
  end

  def self.define(name, &block)
    puts "Loading Plugin: #{name}"
    plugin = PluginBase.new(@bot)
    plugin.instance_eval(&block)

    plugin.commands.each do |c| 
      if Plugins.commands.has_key?(c[:name])
        puts "Sorry, a command called #{c[:name]} is already implemented by the plugin: #{Plugins.commands[c[:name]][:plugin_name]}"
      else
        Plugins.commands[c[:name]] = {:plugin_name => name, :type => c[:type]}
      end
    end
    
    Plugins.registered[name] = plugin
  end
end