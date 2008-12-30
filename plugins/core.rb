Plugins.define "Core" do
  author "Benjamin Birnabum"
  desc "This provides some basic core functionality"
  version "0.0.1"

  ## Admin Commands
  def admin_reload(args)
    @bot.load_plugins
    args[:buddy].send_im("Reloading Complete")
  end

  def admin_quit(args)
    args[:buddy].send_im("Bye Bye!")
    @bot.quit
  end
  
  def admin_unregister_plugin(args)
    if args[:cmd_args].size < 1
      args[:buddy].send_im("You have to give me a plugin name...")
      return
    end
    
    plugin_name = args[:cmd_args][0]
    if Plugins.registered.has_key?(plugin_name)
      Plugins.unregister_plugin(plugin_name)
      args[:buddy].send_im("Plugin #{plugin_name} unregistered successfully")
    else
      args[:buddy].send_im("That plugin doesn't exist.")
    end    
  end

  def admin_register_plugin(args)
    if args[:cmd_args].size < 1
      args[:buddy].send_im("You have to give me a plugin name...")
      return
    end
    
    plugin_name = args[:cmd_args][0]
    if Plugins.registered.has_key?(plugin_name)
      args[:buddy].send_im("That plugin is already registered.")
      return
    end
    
    plugin_path = "#{BotConfig::PluginDir}/#{plugin_name.downcase}.rb"
    if File.exist?(plugin_path)
      load plugin_path
      args[:buddy].send_im("Plugin #{plugin_name} registered successfully")
    else
      args[:buddy].send_im("Sorry, I can't find that plugin")
    end
  end

  ## Public Commands
  def public_stats(args)
    args[:buddy].send_im("I have #{Plugins.registered.size} Plugins and #{Plugins.commands.size} commands")
  end
  
  def public_date(args)
    args[:buddy].send_im("#{Time.now}")
  end

  def public_do(args)
    do_cmd = args[:cmd_args].last.to_sym
    commands = {
      :poo => "does a poo",
      :fart => 'farts loudy.....it stinks',
      :burp => 'burps',
      :dance => 'does the moonwalk',
      :flying => 'flies around the room',
      :wee => 'does wee in the corner',
      :pushups => 'is too lazy'
    }
    
    if action = commands[do_cmd]
      args[:buddy].send_im("*#{BotConfig::Name} #{action}*")
    end
  end

  def public_about(args)
    cmd_args = args[:cmd_args]
    case cmd_args.size
    when 2:
      if cmd_args[0] == 'plugin'
        plugin = Plugins.registered[cmd_args[1]]
        if plugin
          args[:buddy].send_im("About #{cmd_args[1]}<br/>#{plugin}")
        else
          args[:buddy].send_im("That plugin doesn't exist!")
        end
      end
    when 1:
      args[:buddy].send_im("You need to give me a plugin name..") if cmd_args[0] == 'plugin'
      args[:buddy].send_im("Registered Plugins: #{Plugins.registered.keys.sort.join(", ")}") if cmd_args[0] == 'plugins'
    else
      args[:buddy].send_im("Thanks for asking about me!!")
    end
  end

  def public_help(args)
    if args[:cmd_args].empty?
      args[:speaker].send_im("Listing available commands in each plugin:")
      Plugins.registered.keys.sort.each do |name|
        plugin = Plugins.registered[name]
        commands = plugin_commands_for_user(name, args[:speaker].screen_name)
        args[:speaker].send_im("#{name} Commands: #{commands.sort.join(", ")}") unless commands.empty?
      end
    end
  end

  ## Helper methods
  def plugin_commands_for_user(plugin_name, username)
    commands = []
    Plugins.commands.keys.sort.each do |name|
      command = Plugins.commands[name]
      next if command[:plugin_name] != plugin_name
      next if command[:type] == 'admin' && !BotConfig::AdminUsers.include?(username)
      commands << name
    end
    commands
  end
end
