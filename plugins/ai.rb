require 'net/http'

Plugins.define "AI" do
  author "Benjamin Birnbaum"
  desc "Chat Bot"
  version "0.0.1"
  
  @non_directed_responses = ['farts loudly', 'raises an eyebrow', 'yawns', 'shifts uncomfortably', 'looks around', 'stretches', 'scratches its head',
                             'falls asleep', 'drools', 'dribbles', 'looks away', 'goes back to doing nothing', 'blinks rapidly', 'mumbles']
  
  def on_non_directed_message(message, speaker, buddy, command_executed)
    return if command_executed || message.match(Regexp.new(@bot.my_names.join("|"), Regexp::IGNORECASE)).nil?
    
    my_name = @bot.my_names.randomly_pick(1)
    buddy.send_im("*#{my_name} #{@non_directed_responses.randomly_pick(1)}*")
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