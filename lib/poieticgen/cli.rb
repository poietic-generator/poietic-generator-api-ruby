# vim: set ts=2 sw=2 et:

require 'poieticgen'

module PoieticGen
  class Cli < Thor
    desc "list", "List all groups and session"
    option :all, :type => :boolean, :aliases => :a
    def list
      configure
      group_filter = if options[:all] then {}
                     else { closed: false }
                     end
      groups = PoieticGen::BoardGroup.all(group_filter)
      groups.each do |group|
        group_name = group.canonical_name
        group_openess = group.closed ? "closed" : "open"
        group_users =
          if group.live? and (group.live_users_count > 0) then
            "%d users live!" % group.live_users_count
          else
            "No user connected"
          end 

        puts "GROUP id %3d %20s - %s - %s - %s" % [ 
          group.id, 
          group_name, 
          group.token,
          group_openess,
          group_users  
        ]

        board_filter = if options[:all] then {}
                       else { closed: false }
                       end
        boards = group.boards.all(board_filter)
        puts "      (no session)" if boards.empty?
        boards.each do |board|
          stop = if (board.end_timestamp > 0) then
                   Time.at(board.end_timestamp).utc.iso8601
                 else
                   "none"
                 end
          #pp s.end_timestamp
          puts "- SESSION % 3d - USERS %s - FROM %s .. TO %s]" % [ 
            board.id, 
            board.users.all(did_expire: false).count,
            Time.at(board.timestamp).utc.iso8601,
            stop,
          ]
        end
      end # board groups
    end 

    desc "create [-n NAME]", "Create a new session group"
    option :name, :type => :string, :aliases => :n
    def create
      configure
      PoieticGen::BoardGroup.create @config.board, options[:name]
    end

    desc "rename GROUP_ID NEWLABEL", "Rename group GROUP_ID"
    def rename id, new_label
      configure
      group = PoieticGen::BoardGroup.first(:id => id.to_i)
      group.name = new_label
      pp group

      begin
        group.save
      rescue DataMapper::SaveFailureError => e
        STDERR.puts e.resource.errors.inspect
        raise e
      end
    end

=begin
    desc "finish SESSION_ID", "Finish session SESSION_ID"
    def finish id
      configure
      session = PoieticGen::Board.first(:id => id.to_i)
      session.close
      STDERR.puts "FIXME: kill users and zones"
      exit 1
    end
=end

    option :all, :type => :boolean, :aliases => :a
    desc "delete (-a | GROUP_ID)", "Delete session GROUP_ID"
    def delete id=nil
      configure
      if options[:all] then
        groups = PoieticGen::BoardGroup.all
        res = groups.destroy
      else
        group = PoieticGen::BoardGroup.first(:id => id.to_i)
        if group.nil? then
          puts "ERROR: Session %s does not exist." % id.to_i
          exit 1
        end
        group.boards.destroy!
        res = group.destroy!
        pp res
      end
    end

    desc "shapshot SESSION_ID OFFSET FILENAME [FACTOR]", 
      "Dump snapshot in session SESSION_ID at OFFSET and save it in FILENAME"
    def snapshot id, offset, filename, factor=1
      configure
      board = PoieticGen::Board.first(:id => id.to_i)

      if board.nil? then
        STDERR.puts "ERROR: Session %s does not exist" % id
        exit 1
      end

      timestamp = board.timestamp + offset
      end_timestamp = if board.closed then 
                        board.end_timestamp 
                      else Time.now.to_i 
                      end

      if offset < 0 or timestamp > end_timestamp then
        STDERR.puts "ERROR: Offset '%d' out of bounds (%d -> %d)" %
          [ offset, 0, (end_timestamp - board.timestamp) ]
        exit 1
      end

      zones = board.load_board(board.timestamp + offset)
      width, height, diff_x, diff_y = board.max_size

      _take_snap(zones, filename, factor.to_i, width, height, diff_x, diff_y)
    end

    desc "range SESSION_ID", "Duration of session SESSION_ID"
    def range id
      configure
      board = PoieticGen::Board.first(:id => id.to_i)

      # FIXME: when not closed, remove ~30 seconds from finish
      start = board.timestamp
      finish = if board.closed then board.end_timestamp 
               else Time.now.to_i 
               end

      puts "%d" % (finish - start)
    end

    option :start, 
      :type => :numeric, 
      :default => 0, 
      :aliases => :s,
      :desc => "Start time of sequence (in FIXME unit)"
    option :length, 
      :type => :numeric, 
      :default => 0, 
      :aliases => :l,
      :desc => "Duraction length of sequence (in FIXME unit)"
    option :interval, 
      :type => :numeric, 
      :default => 1, 
      :aliases => :i,
      :desc => "Interval between two snapshots in sequence (in FIXME unit)"
    option :factor, 
      :type => :numeric, 
      :default => 1, 
      :aliases => :f,
      :desc => "Resolution factor for output images (integer)"
    desc "sequence SESSION_ID DIRECTORY", 
      "Dump a sequence of snapshots in session ID between OFFSET_START " +
       "and OFFSET_END with INTERVAL, and save it in DIRECTORY"
    def sequence id, directory
      configure
      board = PoieticGen::Board.first(:id => id.to_i)

      if board.nil? then
        puts "The board %s does not exist" % id
        return
      end

      offset_start = board.timestamp + options[:start]
      offset_end = if options[:length] <= 0 then
                     if board.closed then board.end_timestamp else Time.now.to_i end
                   else
                     offset_start + options[:length]
                   end
      interval = options[:interval]
      factor = options[:factor]

      # FIXME: check offsets (board.timestamp <= offset_start < offset_end <= board.end_timestamp|now)

      FileUtils.mkdir_p directory

      width, height, diff_x, diff_y = board.max_size
      board_timelines = board.timelines
      zones = board.load_board offset_start
      last_offset = offset_start
      file_id = 0

      (offset_start..offset_end).step(interval).each do |offset|
        filename = '%s/image-%07d.png' % [ directory, file_id ]
        file_id += 1

        if offset > offset_start then
          # get events since the snapshot
          timelines = board_timelines.all(
            :timestamp.gt => last_offset,
            :timestamp.lte => offset,
            :order => [ :timestamp.asc ]
          )
          zones = board.apply_events timelines, zones
        end

        puts "zones at #{file_id} : #{zones.length}"
        _take_snap zones, filename, factor, width, height, diff_x, diff_y

        last_offset = offset
      end
    end

    option :outfps, :type => :numeric, :default => 24
     option :outsize, :type => :string, :default => "320:-1"
    desc "video DIRECTORY FILENAME [-outfps v]", "Create a video from a DIRECTORY with FPS (using FFMPEG) and save it in FILENAME"
    def video directory, filename
      ffmpeg_cmd = [
        "ffmpeg ",
        "-r %d",
         "-i '%s/image-%%7d.png'",
         "-vf \"scale=%s\"",
         "-sws_flags neighbor+full_chroma_inp",
         "-r %d",
         "%s"
      ].join(' ')
      ffmpeg_args = [ 
        options[:outfps], 
        directory, 
        options[:outsize], 
        options[:outfps], 
        filename 
      ]
      err = system( ffmpeg_cmd % ffmpeg_args)
      if !err then
        puts "Error while creating video"
      end

      puts "Video created as '%s'" % filename
    end

    private

    def configure
      $stdout = File.new '/dev/null', 'w' # mute STDOUT

      @config = PoieticGen::ConfigManager.new PoieticGen::ConfigManager::DEFAULT_CONFIG_PATH
      DataMapper.finalize
      DataMapper::Logger.new(STDERR, :info)
      #DataMapper::Logger.new(STDERR, :debug)
      hash = @config.database.get_hash
      #pp "db hash :", hash
      DataMapper.setup(:default, hash)

      # raise exception on save failure (globally across all models)
      DataMapper::Model.raise_on_save_failure = true

      DataMapper.auto_upgrade!

      $stdout = STDOUT # unmute STDOUT
    rescue DataObjects::SQLError
      $stdout = STDOUT # unmute STDOUT
      STDERR.puts "ERROR: unable to connect to database. Please verify settings."
      exit 1
    end


    def _take_snap zones, filename, factor, width, height, diff_x, diff_y
      black = PoieticGen::CLI::Color.from_rgb(0, 0, 0)
      image = PoieticGen::CLI::Image.new width * factor, height * factor, black

      zones.each do |index, zone|
        zone_x, zone_y = zone.position

        # Make zone position absolute (depends on the topleft of bounding box)
        zone_x = (zone_x * zone.width) - diff_x
        zone_y = (zone_y * zone.height) - diff_y

        # Reverse the y axis of zone for image output
        zone_y = height - zone_y - zone.height

        (0..(zone.height * zone.width)-1).each do |i|
          image.draw_rect(
            (zone_x + (i % zone.width)) * factor,
            (zone_y + (i / zone.width)) * factor,
            factor, factor,
            (PoieticGen::CLI::Color.from_hex zone.data[i])
          )
        end
      end

      image.save filename
    end
  end
end

