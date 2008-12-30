module Net::TOC
  
  # A high-level interface to TOC. It supports asynchronous message handling through the use of threads, and maintains a list of buddies.
  class Client
    include Net::TOC
    
    attr_reader :buddy_list, :screen_name
    
    # You must initialize the client with your screen name and password.
    # If a block is given, Client#listen will be invoked with the block after initialization.
    def initialize(screen_name, password, &optional_block) # :yields: message, buddy, auto_response, client
      @conn = Connection.new(screen_name)
      @screen_name = format_screen_name(screen_name)
      @password = password
      @callbacks = {}
      @buddy_list = BuddyList.new(@conn)
      add_callback(:config, :config2) { |v| @buddy_list.decode_toc v }
      add_callback(:update_buddy, :update_buddy2) { |v| update_buddy v }
      on_error do | error |
        $stderr.puts "Error: #{error}"
      end
      listen(&optional_block) if block_given?
    end
    
    # Connects to the server and starts an event-handling thread.
    def connect(server="toc.oscar.aol.com", port=9898, oscar_server="login.oscar.aol.com", oscar_port=5190)
      @conn.open(server, port)
      code = 7696 * @screen_name[0] * @password[0]
      @conn.toc2_signon(oscar_server, oscar_port, @screen_name, roasted_pass, "english", "\"TIC:toc.rb\"", 160, code)

      @conn.recv do |msg, val|
        if msg == :sign_on
          @conn.toc_add_buddy(@screen_name)
          @conn.toc_init_done
          @conn.toc_set_caps(capabilities.join(" "))
          @conn.add_permit
          @conn.add_deny
        end
      end
      
      @thread.kill unless @thread.nil? # ha
      @thread = Thread.new { loop { event_loop } }
    end
    
    # Disconnects and kills the event-handling thread.  You may still add callbacks while disconnected.
    def disconnect
      @thread.kill unless @thread.nil?
      @thread = nil
      @conn.close
    end
    
    # Connects to the server and forwards received IMs to the given block. See Client#connect for the arguments.
    def listen(*args) # :yields: message, buddy, auto_response, client
      on_im do | message, buddy, auto_response |
        yield message, buddy, auto_response, self
      end
      connect(*args)
      wait
    end
    
    # Pass a block to be called every time an IM is received. This will replace any previous on_im handler.
    def on_im
      raise ArgumentException, "on_im requires a block argument" unless block_given?
      add_callback(:im_in, :im_in2) do |val|
        screen_name, auto, f2, *message = *val.split(":")
        message = message.join(":")
        buddy = @buddy_list.buddy_named(screen_name)
        auto_response = auto == "T"
        yield message, buddy, auto_response
      end
    end
    
    # Pass a block to be called every time an error occurs. This will replace any previous on_error handler, including the default exception-raising behavior.
    def on_error
      raise ArgumentException, "on_error requires a block argument" unless block_given?
      add_callback(:error) do |val|
        code, param = *val.split(":")
        error = ErrorCode[code.to_i]
        error = "An unknown error occurred." if error.nil?
        error.gsub!("<param>", param) unless param.nil?
        yield error
      end
    end
    
    # Sets your status to away and +away_message+ as your away message.
    def go_away(away_message)
      @conn.toc_set_away "\"#{away_message.gsub("\"","\\\"")}\""
    end
    
    # Sets your status to available.
    def come_back
      @conn.toc_set_away
    end
    
    # Sets your idle time in seconds. You only need to set this once; afterwards, the server will keep track itself.
    # Set to 0 to stop being idle.
    def idle_time=(seconds)
      @conn.toc_set_idle seconds
    end
    
    # Waits for the event-handling thread for +limit+ seconds, or indefinitely if no argument is given. Use this to prevent your program from exiting prematurely.
    # For example, the following script will exit right after connecting:
    #   client = Net::TOC.new("screenname", "p455w0rd")
    #   client.connect
    # To prevent this, use wait:
    #   client = Net::TOC.new("screenname", "p455w0rd")
    #   client.connect
    #   client.wait
    # Now the program will wait until the client has disconnected before exiting.
    def wait(limit=nil)
      @thread.join limit
    end
    
    # Returns a list of this client's capabilities.  Not yet implemented.
    def capabilities
      ['09461343-4C7F-11D1-8222-444553540000', '09461348-4C7F-11D1-8222-444553540000'] # TODO
    end
    
    private
    
    # Returns an "encrypted" version of the password to be sent across the internet.
    # Decrypting it is trivial, though.
    def roasted_pass
      tictoc = "Tic/Toc".unpack "c*"
      pass = @password.unpack "c*"
      roasted = "0x"
      pass.each_index do |i|
        roasted << sprintf("%02x", pass[i] ^ tictoc[i % tictoc.length])
      end
      roasted
    end
    
    def update_buddy(val)
      screen_name = val.split(":").first.chomp
      buddy = @buddy_list.buddy_named(screen_name)
      buddy.raw_update(val)
    end
    
    def add_callback(*callbacks, &block)
      callbacks.each do |callback|
        @callbacks[callback] = block;
      end
    end
    
    def event_loop
      @conn.recv do |msg, val|
        begin
          @callbacks[msg].call(val) unless @callbacks[msg].nil?
        rescue Exception => e
          Thread.main.raise(e)
        end
      end
    end
  end
end