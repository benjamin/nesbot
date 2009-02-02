Plugins.define "8ball" do
  author "Benjamin Birnbaum"
  desc "A Magic 8 Ball"
  version "0.0.1"

  @responses = [
    "As I see it, yes",
    "Ask again later",
    "Better not tell you now",
    "Cannot predict now",
    "Concentrate and ask again",
    "Don't count on it",
    "It is certain",
    "It is decidedly so",
    "Most likely",
    "My reply is no",
    "My sources say no",
    "Outlook good",
    "Outlook not so good",
    "Reply hazy, try again",
    "Signs point to yes",
    "Very doubtful",
    "Without a doubt",
    "Yes",
    "Yes - definitely",
    "You may rely on it",
  ]

  def public_8ball(args)
    if args[:cmd_args].size == 0
      response = "It would help if you posed a question for the almighty 8Ball!"
    else
      response = @responses.randomly_pick(1)
    end
    
    if args[:buddy] != args[:speaker]
      response = "#{args[:speaker].screen_name}, #{response}"
    end
    
    args[:buddy].send_im(response)
  end
end