#!/usr/bin/ruby -w
#
# = Name
# Audioscrobbler
#
# == Description
# This file contains an implementation of the Audioscrobbler plugin
# protocol, used to submit playlist history to Last.fm.  The protocol
# description is located at
# http://www.audioscrobbler.net/development/protocol/ .
#
# == Version
# 0.1.0
#
# == Author
# Daniel Erat <dan-ruby@erat.org>
#
# == Copyright
# Copyright 2007 Daniel Erat
#
# == License
# GNU GPL; see COPYING
#
# == Changes
# 0.0.1  Initial release
# 0.0.2  Upgraded from v1.1 to v1.2 of the Audioscrobbler protocol.  This means:
#        - "Now Playing" notifications
#        - callers should now submit when tracks stop playing instead of as
#          soon as the submission criteria is met
#        - track numbers can be submitted
#        Also added a race condition that I haven't bothered fixing (I
#        think I'm the only person using this library?).
# 0.1.0  Catch an exception when the server gives us a bogus now-playing
#        URL, as happened to me yesterday. :-P

require "cgi"
require "md5"
require "net/http"
require "thread"
require "uri"

# = Audioscrobbler
#
# == Description
# Queue music tracks as they are played and submit the track information to
# Last.fm (http://www.last.fm) using the Audioscrobbler plugin protocol
# (http://www.audioscrobbler.net/).
#
# Version 1.2 of the plugin protocol
# (http://www.audioscrobbler.net/development/protocol/) is currently used.
#
# == Usage
#  require "audioscrobbler"
#  scrob = Audioscrobbler.new("user",       # Audioscrobbler username
#                             "pass",       # Audioscrobbler password
#                             "queue.txt",  # file for storing queue
#                            )
#
#  # Replace these with the client ID that's been assigned to your
#  # plugin by the Audioscrobbler folks and your plugin's version number.
#  scrob.client = "tst"
#  scrob.version = "1.0"
#
#  # If you don't start the submitter, tracks will just pile up in the
#  # submission queue.
#  scrob.start_submitter_thread
#
#  # Report the currently-playing song:
#  scrob.report_now_playing("Beach Boys",      # artist
#                           "God Only Knows",  # title
#                           175,               # track length, in seconds
#                           "Pet Sounds",      # album (optional)
#                           "",                # MusicBrainzID (optional)
#                           "8",               # track number (optional)
#                          )
#
#  # Now wait until the Audioscrobbler submission criteria has been met and
#  # the track has finished playing.
#
#  # And then queue the track for submission:
#  scrob.enqueue("Beach Boys",      # artist
#                "God Only Knows",  # title
#                175,               # track length, in seconds
#                1125378558,        # track start time
#                "Pet Sounds",      # album (optional)
#                "",                # MusicBrainzID (optional)
#                "8",               # track number (optional)
#               )
class Audioscrobbler
  # Default URL to connect to for the handshake.
  DEFAULT_HANDSHAKE_URL = "http://post.audioscrobbler.com/"

  # Default minimum interval to wait between successful submissions.
  DEFAULT_SUBMIT_INTERVAL_SEC = 5

  # Default plugin name and version to report to the server.
  # You MUST set these to the values that you've registered before
  # you can distribute your plugin to anyone (including beta testers).
  DEFAULT_CLIENT = "tst"
  DEFAULT_VERSION = "1.0"

  # Maximum number of tracks that will be accepted in a single
  # submission.  This is a server-imposed limit.
  MAX_TRACKS_IN_SUBMISSION = 10

  ##
  # Create a new Audioscrobbler object.
  #
  # @param username  Audioscrobbler account username
  # @param password  Audioscrobbler account password
  # @param filename  file used for on-disk storage of not-yet-submitted
  #                  tracks
  #
  def initialize(username, password, filename=nil)
    @username = username
    @password = password
    @queue = SubmissionQueue.new(filename)
    @verbose = false
    @client = DEFAULT_CLIENT
    @version = DEFAULT_VERSION

    @handshake_url = DEFAULT_HANDSHAKE_URL
    @last_handshake_time = nil
    @handshake_backoff_sec = 0
    @hard_failures = 0

    @session_id = nil
    @submit_url = nil
    @now_playing_url = nil
    @submit_interval_sec = DEFAULT_SUBMIT_INTERVAL_SEC
  end
  attr_accessor :username, :password, :verbose
  attr_accessor :client, :version, :handshake_url

  ##
  # Update the backoff interval after handshake failure.  If we haven't
  # failed yet, we wait a minute; otherwise, we wait twice as long as last
  # time, up to a maximum of two hours.
  #
  # @param message  string logged to stderr if verbose logging is enabled
  #
  def handle_handshake_failure(message)
    vlog(message)
    if @handshake_backoff_sec < 60
      @handshake_backoff_sec = 60
    elsif @handshake_backoff_sec < 2 * 60 * 60
      @handshake_backoff_sec *= 2
    else
      @handshake_backoff_sec = 2 * 60 * 60
    end
  end
  private :handle_handshake_failure

  ##
  # Attempt to handshake with the server.
  # Returns true on success and false on failure.
  # If the connection fails, @handshake_backoff_sec is also updated
  # appropriately.  Wait this long before trying to handshake again.
  #
  def do_handshake(can_sleep=true)
    # Sleep before trying again if needed.
    if can_sleep and
       @last_handshake_time != nil and
       @last_handshake_time + @handshake_backoff_sec > Time.now
      sleep(@last_handshake_time + @handshake_backoff_sec - Time.now)
    end

    @last_handshake_time = Time.now
    timestamp = Time.now.to_i.to_s
    auth_token = MD5.hexdigest(MD5.hexdigest(@password) + timestamp)

    args = {
      'hs' => 'true',
      'p'  => '1.2',
      'c'  => @client,
      'v'  => @version,
      'u'  => @username,
      't'  => timestamp,
      'a'  => auth_token,
    }
    arg_pairs = args.collect do |attr, value|
      CGI.escape(attr.to_s) + '=' + CGI.escape(value.to_s)
    end
    url = @handshake_url + '?' + arg_pairs.join('&')

    vlog("Beginning handshake with #@handshake_url")

    begin
      data = Net::HTTP.get_response(URI.parse(url)).body
    rescue Exception
      handle_handshake_failure(
        "Read of #@handshake_url for handshake failed: #{$!}")
      return false
    end

    # Make sure that we got something back.
    if not data
      handle_handshake_failure(
        "Got empty response from server during handshake")
      return false
    end

    # The expected response is:
    # OK
    # Session ID
    # Now-Playing URL
    # Submission URL
    lines = data.split("\n")
    response = lines[0].split[0]
    if response != 'OK'
      handle_handshake_failure(
        "Got \"#{lines[0]}\" from server during handshake (expected OK)")
      return false
    end

    if lines.length != 4
      handle_handshake_failure(
        "Got #{lines.length} during handshake (expected 4)")
      return false
    end

    # Create our response based on the server's challenge and
    # save the submission URL.
    @session_id, @now_playing_url, @submit_url = lines[1,3]
    vlog("Got session ID #@session_id, submission URL " \
         "#@submit_url, and now-playing URL #@now_playing_url")

    @handshake_backoff_sec = 0
    @hard_failures = 0
    return true
  end
  private :do_handshake

  ##
  # Start the submitter thread and return.
  #
  def start_submitter_thread
    @submit_thread = Thread.new do
      while true
        # Wait until there are some tracks in the queue.
        tracks = @queue.peek(MAX_TRACKS_IN_SUBMISSION)

        # Keep trying to handshake until we're successful.
        do_handshake while not @session_id

        # Might as well re-check in case more tracks have shown up
        # during the handshake.
        tracks = @queue.peek(MAX_TRACKS_IN_SUBMISSION)
        vlog("Submitting #{tracks.length} track(s)")

        # Construct our argument list.
        args = { "s" => @session_id }
        for i in 0..tracks.length-1
          args.update({
            "a[#{i}]" => tracks[i].artist,
            "t[#{i}]" => tracks[i].title,
            "i[#{i}]" => Time.at(tracks[i].start_time).to_i,
            "o[#{i}]" => 'P',
            "r[#{i}]" => '',
            "l[#{i}]" => tracks[i].length.to_s,
            "b[#{i}]" => tracks[i].album,
            "n[#{i}]" => tracks[i].track_num,
            "m[#{i}]" => tracks[i].mbid,
          })
        end
        # Convert it into a single escaped string for the body.
        body = args.collect {|k, v| "#{k}=" + CGI.escape(v.to_s) }.join('&')

        begin
          url = URI.parse(@submit_url)
          headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
          data = Net::HTTP.start(url.host, url.port) do |http|
            http.post(url.path, body, headers).body
          end
        rescue Exception
          vlog("Submission failed -- couldn't read #@submit_url: #{$!}")
        else
          # Check whether the submission was successful.
          lines = data.split("\n")
          if not lines[0]
            vlog("Submission failed -- got empty response")
          elsif lines[0] == "OK"
            vlog("Submission was successful")
            @queue.delete(tracks.length)
          elsif lines[0] == "BADSESSION"
            vlog("Submission failed -- session is invalid")
            # Unset the session ID so we'll re-handshake.
            @session_id = nil
          else
            vlog("Submission failed -- got unknown response \"#{lines[0]}\"")
            @hard_failures += 1
          end
        end

        if @hard_failures >= 3
          vlog("Got #@hard_failures failures; re-handshaking")
          @session_id = nil
        end

        vlog("Sleeping #@submit_interval_sec sec before checking for " \
             "more tracks")
        sleep(@submit_interval_sec)
      end
    end
  end

  ##
  # Report the track that is currently playing.
  # Returns true if the report was successful and false otherwise.
  #
  # @param artist      artist name
  # @param title       track name
  # @param length      track length
  # @param album       album name
  # @param mbid        MusicBrainz ID
  # @param track_num   track number on album
  #
  def report_now_playing(artist, title, length, album="", mbid="",
                         track_num='')
    vlog("Reporting \"#{artist} - #{title}\" as now-playing")

    # FIXME(derat): Huge race condition here between us and the submission
    # thread, but I am to lazy to fix it right now.
    if not @session_id
      do_handshake(false)
    end

    # Construct our argument list.
    args = {
      's' => @session_id,
      'a' => artist,
      't' => title,
      'b' => album,
      'l' => length.to_i,
      'n' => track_num,
      'm' => mbid,
    }
    # Convert it into a single escaped string for the body.
    body = args.collect {|k, v| "#{k}=" + CGI.escape(v.to_s) }.join('&')

    success = false
    begin
      url = URI.parse(@now_playing_url)
    rescue Exception
      vlog("Submission failed -- couldn't parse now-playing " +
           "URL \"#@now_playing_url\"")
    else
      headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
      begin
        data = Net::HTTP.start(url.host, url.port) do |http|
          http.post(url.path, body, headers).body
        end
      rescue Exception
        vlog("Submission failed -- couldn't read #@now_playing_url: #{$!}")
      else
        data.chomp!
        if data == "OK"
          vlog("Now-playing report was successful")
          success = true
        else
          vlog("Now-playing report failed -- got \"#{data}\"")
        end
      end
    end
    success
  end

  ##
  # Enqueue a track for submission.
  #
  # @param artist      artist name
  # @param title       track name
  # @param length      track length
  # @param start_time  track start time, as UTC unix time
  # @param album       album name
  # @param mbid        MusicBrainz ID
  # @param track_num   track number on album
  #
  def enqueue(artist, title, length, start_time, album="", mbid="",
              track_num=nil)
    if not length or length < 30
      log("Ignoring #{artist} - #{title}, as it is #{length} second(s) " \
          "long (min is 30 seconds)")
      return
    elsif not artist or artist == ''
      log("Ignoring #{title}, as it is missing an artist tag")
      return
    elsif not title or title == ''
      log("Ignoring #{artist}, as it is missing a title tag")
      return
    elsif not start_time or start_time <= 0
      log("Ignoring #{artist} - #{title} with bogus start time #{start_time}")
      return
    end

    @queue.append(artist, title, length, start_time, album, mbid, track_num)
  end

  ##
  # Log a message, along with the current time, to stderr.
  #
  # @param message  message to log
  #
  def log(message)
    STDERR.puts(Time.now.strftime("%Y-%m-%d %H:%M:%S") + " " + message.to_s)
  end
  private :log

  ##
  # Only log if verbose logging is enabled.
  #
  # @param message  message to log
  #
  def vlog(message)
    log(message) if @verbose
  end
  private :vlog

  ##
  # A synchronized, backed-up-to-disk queue holding tracks for submission.
  # The synchronization is only sufficient for a single reader and writer.
  #
  class SubmissionQueue
    ##
    # constructor
    # If a filename is supplied, it will be used to:
    # a) load tracks that were previously played but not submitted
    # b) save the state of the queue for later use in a)
    #
    # @param filename  queue filename (optional)
    #
    def initialize(filename=nil)
      @filename = filename
      @queue = Array.new
      @mutex = Mutex.new
      @condvar = ConditionVariable.new
      if @filename and File.exist?(@filename)
        File.open(@filename, "r").each do |line|
          @queue.push(PlayedTrack.deserialize(line.chomp))
        end
      end
    end

    ##
    # Append a played track to the submission queue.
    #
    # @param artist      artist name
    # @param title       track name
    # @param length      track length
    # @param start_time  track start time, as UTC unix time
    # @param album       album name
    # @param mbid        MusicBrainz ID
    # @param track_num   track number on album
    #
    def append(artist, title, length, start_time, album="", mbid="",
               track_num=nil)
      @mutex.synchronize do
        track = PlayedTrack.new(artist, title, length, start_time, album, mbid,
                                track_num)
        File.open(@filename, "a") {|f| f.puts(track.serialize) } if @filename
        @queue.push(track)
        @condvar.signal
      end
      self
    end

    ##
    # Get tracks from the beginning of the queue.
    # An array of PlayedTrack objects is returned.  The tracks are _not_
    # removed from the queue.  If the queue is empty, the method blocks
    # until a track is placed on the queue.
    #
    # @param max_tracks  maximum number of tracks to return
    #
    def peek(max_tracks=1)
      @mutex.synchronize do
        @condvar.wait(@mutex) if @queue.empty?
        @queue[0, max_tracks]
      end
    end

    ##
    # Delete tracks from the beginning of the queue.
    # If more tracks are requested than are in the queue, the queue is
    # cleared.
    #
    # @param num_tracks  number of tracks to delete
    #
    def delete(num_tracks)
      if not @queue.empty?
        @mutex.synchronize do
          @queue = @queue[num_tracks..@queue.length-1]
          if @filename
            file = File.open(@filename, "w")
            @queue.each {|track| file.puts(track.serialize) }
            file.close
          end
        end
      end
      self
    end

    # A track that's been played.
    class PlayedTrack
      ##
      # constructor
      #
      # @param artist      artist name
      # @param title       track name
      # @param length      track length
      # @param start_time  track start time, as UTC unix time
      # @param album       album name
      # @param mbid        MusicBrainz ID
      # @param track_num   track number on album
      #
      def initialize(artist, title, length, start_time, album="", mbid="",
                     track_num=nil)
        @artist = artist.to_s
        @title = title.to_s
        @length = length.to_i
        @start_time = start_time.to_i
        @album = album ? album.to_s : ""
        @mbid = mbid ? mbid.to_s : ""
        @track_num = track_num ? track_num.to_s : ""
      end
      attr_reader :artist, :title, :length, :start_time, :album, \
                  :mbid, :track_num

      ##
      # Convert this track's information into a form suitable for writing to
      # a text file.  Returns a string.
      #
      def serialize
        parts = [@artist, @title, @length.to_s, @start_time.to_s,
                 @album, @mbid, @track_num]
        parts.collect {|x| x ? CGI.escape(x) : "" }.join("\t")
      end

      ##
      # Undo the operation performed by serialize(), returning a new
      # PlayedTrack object (class method).
      #
      # @param str  serialized PlayedTrack to deserialize (string)
      #
      def self.deserialize(str)
        PlayedTrack.new(*str.split("\t").collect {|x|
          x ? CGI.unescape(x) : "" })
      end

      def ==(other)
        other.class == PlayedTrack and @artist == other.artist and
          @title == other.title and @length == other.length and
          @start_time == other.start_time and @album == other.album and
          @mbid == other.mbid and @track_num == other.track_num
      end
    end  # class PlayedTrack
  end  # class SubmissionQueue
end  # class Audioscrobbler
