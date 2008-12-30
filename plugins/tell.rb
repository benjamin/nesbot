Plugins.define "Tell" do
  author "Benjamin Birnabum"
  desc "Plugin that tells a user something"
  version "0.0.1"

  def public_tell(args)
    if args[:cmd_args].size == 0
      args[:buddy].send_im("Who am I telling what now?")
    elsif args[:cmd_args].size == 1
      args[:buddy].send_im("#{args[:cmd_args][0]}, #{args[:speaker].screen_name} wanted me to tell you.....nothing!")
    else
      reciever = args[:cmd_args].shift
      args[:buddy].send_im("#{reciever}, #{args[:speaker].screen_name} wanted me to tell you: #{args[:cmd_args].join(" ")}")
    end
  end
end