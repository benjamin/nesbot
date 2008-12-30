module Net::TOC
  # The Connection class handles low-level communication using the TOC protocol. You shouldn't use it directly.
  class Connection # :nodoc:
    include Net::TOC

    def initialize(screen_name)
      @user = format_screen_name screen_name
      @msgseq = rand(100000)
    end

    def open(server="toc.oscar.aol.com", port=9898)
      close
      @sock = TCPSocket.new(server, port)

      @sock.send "FLAPON\r\n\r\n", 0

      toc_version = *recv.unpack("N")

      send [1, 1, @user.length, @user].pack("Nnna*"), :sign_on
    end

    def close
      @sock.close unless @sock.nil?
    end

    FrameType = {
      :sign_on => 1,
      :data    => 2
    }

    def send(message, type=:data)
      message << "\0"
      puts "  send: #{message}" if Debug
      @msgseq = @msgseq.next
      header = ['*', FrameType[type], @msgseq, message.length].pack("aCnn")
      packet = header + message
      @sock.send packet, 0
    end

    def recv
      header = @sock.recv 6
      raise CommunicationError, "Server didn't send full header." if header.length < 6

      asterisk, type, serverseq, length = header.unpack "aCnn"

      response = @sock.recv length
      puts "  recv: #{response}" if Debug
      unless type == FrameType[:sign_on]
        message, value = response.split(":", 2)
        unless message.nil? or value.nil?
          msg_sym = message.downcase.to_sym
          yield msg_sym, value if block_given?
        end
      end
      response
    end
    
    private
    
    # Any unknown methods are assumed to be messages for the server.
    def method_missing(command, *args)
      send(([command] + args).join(" "))
    end
  end

end