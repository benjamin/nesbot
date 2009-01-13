require 'net/http'

Plugins.define "Fakts" do
  author "Benjamin Birnbaum"
  desc "Random Fakts"
  version "0.0.1"
  
  def public_fakt(args)
    args[:buddy].send_im("#{args[:speaker].screen_name} your FAKT is: #{get_random_fakt}")
  end
  
  def get_random_fakt
    fakt_id = rand(1169) + 1
    url = "http://www.mentalfloss.com/amazingfactgenerator/"
    response = Net::HTTP.post_form(URI.parse(url), {'p' => fakt_id})
    m = response.body.match /amazing_fact_body.+<p>(.+)<\/p>/m
    return m[1].strip 
  end
end