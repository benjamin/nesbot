Plugins.define "Tell" do
  author "Benjamin Birnbaum"
  desc "Plugin that tells a user something"
  version "0.0.1"

  def public_tell(args)
    word = args[:cmd_args].last.include?('?') ? "ask" : "tell"
    
    if args[:cmd_args].size == 0
      tell = "Who am I #{word}ing what now?"
    elsif args[:cmd_args].size == 1
      tell = "#{args[:cmd_args][0]}, #{args[:speaker].screen_name} wanted me to #{word} you.....nothing!"
    else
      reciever = args[:cmd_args].shift
      tell = "#{reciever}, #{args[:speaker].screen_name} wanted me to #{word} you: #{args[:cmd_args].join(" ")}"
    end
    
    if args[:buddy] == args[:speaker] && args[:cmd_args].size > 0
      @bot.send_im_to(BotConfig::BlastGroup, tell)
    else
      args[:buddy].send_im(tell)
    end
  end
end