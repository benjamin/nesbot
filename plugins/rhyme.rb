require 'net/http'

Plugins.define "Rhyme" do
  author "Benjamin Birnabum"
  desc "Lets you find rhyming words"
  version "0.0.1"
    
  def public_rhyme(args)
    if args[:cmd_args].size == 0
      args[:buddy].send_im('Would help if you gave me a word to rhyme!')
      return
    end
    
    word = args[:cmd_args].first
    rhymes = get_rhymes(word)
    
    if rhymes.size > 0
      args[:buddy].send_im("Words that rhyme with #{word} are: #{rhymes}")
    else
      args[:buddy].send_im("There are no words that rhyme with #{word}!")
    end
  end
  
  def get_rhymes(word)
    url = "http://azarask.in/services/rhyme/"
    response = Net::HTTP.post_form(URI.parse(url), {'q' => word})
    response.body[1,response.body.size-3].gsub('"', '')
  end
end