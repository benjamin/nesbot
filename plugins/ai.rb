require 'net/http'

Plugins.define "AI" do
  author "Benjamin Birnbaum"
  desc "Chat Bot"
  version "0.0.1"
   
  def on_non_directed_message(message, speaker, buddy, command_executed)
    #search for my name somewhere on the line.....
  end
  
  def on_directed_message(message, speaker, buddy, command_executed)
    return if command_executed
    buddy.send_im("#{speaker.screen_name}: #{get_alice_response(message)}")
  end
  
  def on_private_message(message, buddy, command_executed)
    return if command_executed
    buddy.send_im(get_alice_response(message))
  end
  
  def get_alice_response(msg)
    botid = "f5d922d97e345aa1"
    botcust = "a47d79b2be70536d"
    url = "http://www.pandorabots.com/pandora/talk"
    response = Net::HTTP.post_form(URI.parse(url), {'input' => msg, 'botid' => botid, 'botcust2' => botcust, 'skin' => 'custom_input'})    
    return response.body.split("ALICE:").last.split("\n").first.gsub(/<\/?[^>]*>/, "").strip
  end
end