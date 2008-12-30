Plugins.define "Logger" do
  author "Benjamin Birnabum"
  desc "Logs activities"
  version "0.0.0"

  def on_non_directed_message(message, speaker, buddy, command_executed)
    #buddy.send_im(message)
  end
end
