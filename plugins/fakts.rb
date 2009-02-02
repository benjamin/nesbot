require 'net/http'

Plugins.define "Fakts" do
  author "Benjamin Birnbaum"
  desc "Random Fakts"
  version "0.0.1"
  
  def public_fakt(args)
    args[:buddy].send_im("#{args[:speaker].screen_name} your FAKT is: #{get_random_fakt}")
  end
  
  def get_random_fakt
    fact_items = [{:url => "http://www.mentalfloss.com/amazingfactgenerator/", :regex => /amazing_fact_body.+<p>(.+)<\/p>/mu, :params => {'p' => rand(1169) + 1}},
                  {:url => "http://www.randomfunfacts.com/", :regex => /<strong><i>(.+)<\/i><\/strong>/mu, :params => {}}]
                  
    fakt = fact_items.randomly_pick(1)
    response = Net::HTTP.post_form(URI.parse(fakt[:url]), fakt[:params])
    m = response.body.match fakt[:regex]
    
    return m.nil? ? "Poo" : m[1].strip 
  end
end