module Net::TOC
  class Buddy
    include Net::TOC
    include Comparable
    
    attr_reader :screen_name, :status, :warning_level, :last_signon, :idle_time
    
    def initialize(screen_name, conn) # :nodoc:
      @screen_name = screen_name
      @conn = conn
      @status = :offline
      @warning_level = 0
      @on_status = {}
      @last_signon = :never
      @idle_time = 0
    end
    
    def <=>(other) # :nodoc:
      format_screen_name(@screen_name) <=> format_screen_name(other.screen_name)
    end
    
    # Pass a block to be called when status changes to any of +statuses+. This replaces any previously set on_status block for these statuses.
    # Correct usage is
    #   on_status(:away, :available) do ... end
    # Ensure your arguments are NOT wrapped in an array -- just list them.
    def on_status(*statuses, &callback) #:yields:
      statuses.each { | status | @on_status[status] = callback }
    end
    
    # Returns +true+ unless status == :offline.
    def online?
      status != :offline
    end
    
    # Returns +true+ if status == :available.
    def available?
      status == :available
    end
    
    # Returns +true+ if status == :away.
    def away?
      status == :away
    end
    
    # Returns +true+ if buddy is idle.
    def idle?
      @idle_time > 0
    end
    
    # Sends the instant message +message+ to the buddy. If +auto_response+ is true, the message is marked as an automated response.
    def send_im(message, auto_response=false)
      args = [format_screen_name(@screen_name), "\"" + format_message(message) + "\""]
      args << "auto" if auto_response
      @conn.toc2_send_im *args
    end
    
    # Warns the buddy. If the argument is :anonymous, the buddy is warned anonymously. Otherwise, your name is sent with the warning.
    # You may only warn buddies who have recently IMed you.
    def warn(anon=:named)
      @conn.toc_evil(format_screen_name(@screen_name), anon == :anonymous ? "anon" : "norm")
    end
    
    # The string representation of a buddy; equivalent to Buddy#screen_name.
    def to_s
      screen_name
    end
    
    def raw_update(val) # :nodoc:
      # TODO: Support user types properly.
      name, online, warning, signon_time, idle, user_type = *val.split(":")
      @warning_level = warning.to_i
      @last_signon = Time.at(signon_time.to_i)
      @idle_time = idle.to_i
      if online == "F"
        update_status :offline
      elsif user_type.nil?
        update_status :away
      elsif user_type[2...3] and user_type[2...3] == "U"
        update_status :away
      elsif @idle_time > 0
        update_status :idle
      else
        update_status :available
      end
    end
    
    private
    
    def update_status(status)
      if @on_status[status] and status != @status
        @status = status
        @on_status[status].call
      else
        @status = status
      end
    end
  end
end