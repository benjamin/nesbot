module Net::TOC
  
  # Manages groups and buddies. Don't create one yourself - get one using Client#buddy_list.
  class BuddyList
    include Net::TOC
    
    def initialize(conn) # :nodoc:
      @conn = conn
      @buddies = {}
      @groups = {}
      @group_order = []
    end

    # Constructs a printable string representation of the buddy list.
    def to_s
      s = ""
      each_group do | group, buddies |
        s << "== #{group} ==\n"
        buddies.each do | buddy |
          s << " * #{buddy}\n"
        end
      end
      s
    end
    
    # Calls the passed block once for each group, passing the group name and the list of buddies as parameters.
    def each_group
      @group_order.each do | group |
        buddies = @groups[group]
        yield group, buddies
      end
    end
    
    # Adds a new group named +group_name+.
    # Setting +sync+ to :dont_sync will prevent this change from being sent to the server.
    def add_group(group_name, sync=:sync)
      if @groups[group_name].nil?
        @groups[group_name] = []
        @group_order << group_name
        @conn.toc2_new_group group_name if sync == :sync
      end
    end
    
    # Adds the buddy named +buddy_name+ to the group named +group+. If this group does not exist, it is created.
    # Setting +sync+ to :dont_sync will prevent this change from being sent to the server.
    def add_buddy(group, buddy_name, sync=:sync)
      add_group(group, sync) if @groups[group].nil?
      @groups[group] << buddy_named(buddy_name)
      @conn.toc2_new_buddies("{g:#{group}\nb:#{format_screen_name(buddy_name)}\n}") if sync == :sync
    end
    
    # Removes the buddy named +buddy_name+ from the group named +group+.
    # Setting +sync+ to :dont_sync will prevent this change from being sent to the server.
    def remove_buddy(group, buddy_name, sync=:sync)
      unless @groups[group].nil?
        buddy = buddy_named(buddy_name)
        @groups[group].reject! { | b | b == buddy }
        @conn.toc2_remove_buddy(format_screen_name(buddy_name), group) if sync == :sync
      end
    end

    # Returns the buddy named +name+. If the buddy does not exist, it is created. +name+ is not case- or whitespace-sensitive.
    def buddy_named(name)
      formatted_name = format_screen_name(name)
      buddy = @buddies[formatted_name]
      if buddy.nil?
        buddy = Buddy.new(name, @conn)
        @buddies[formatted_name] = buddy
      end
      buddy
    end
    
    # Decodes the buddy list from raw CONFIG data.
    def decode_toc(val) # :nodoc:
      current_group = nil
      val.each_line do | line |
        letter, name = *line.split(":")
        name = name.chomp
        case letter
        when "g"
          add_group(name, :dont_sync)
          current_group = name
        when "b"
          add_buddy(current_group, name, :dont_sync)
        end
      end
    end
  end

end