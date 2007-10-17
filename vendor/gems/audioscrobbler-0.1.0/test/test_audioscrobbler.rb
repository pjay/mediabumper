#!/usr/bin/ruby -w
#
# = Name
# TestAudioscrobbler
#
# == Description
# This file contains a regression test for the Audioscrobbler class, in the
# unfortunate form of a small, useless implementation of an Audioscrobbler
# track submission server. :(
#
# == Author
# Daniel Erat <dan-ruby@erat.org>
#
# == Copyright
# Copyright 2005 Daniel Erat
#
# == License
# GNU GPL; see COPYING

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'audioscrobbler'
require 'cgi'
require 'md5'
require 'test/unit'
require 'thread'
require 'time'
require 'webrick'

# Stores the outcome of handshakes received by a
# AudioscrobblerHandshakeServlet object.
class AudioscrobblerHandshakeStatus
  def initialize
    clear
  end
  attr_accessor :attempts, :successes, :failures

  def clear
    @attempts = 0
    @successes = 0
    @failures = 0
    self
  end
end


# Implements the handshake portion of the Audioscrobbler protocol.
class AudioscrobblerHandshakeServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server, status, user, password, session_id, submit_url,
                 now_playing_url, plugin_name='tst', plugin_version=0.1)
    @status = status
    @user = user
    @password = password
    @session_id = session_id
    @submit_url = submit_url
    @now_playing_url = now_playing_url
    @plugin_name = plugin_name
    @plugin_version = plugin_version
  end

  def do_GET(req, res)
    @status.attempts += 1
    res['Content-Type'] = "text/plain"

    # Make sure that all of the parameters were supplied and match what we
    # were expecting.
    begin
      if req.query['hs'] != 'true'
        throw "FAILED Handshake not requested"
      elsif req.query['p'] != '1.2'
        throw "FAILED Wrong or missing protocol version"
      elsif req.query['c'] != @plugin_name
        throw "FAILED Wrong or missing plugin name"
      elsif not req.query['v']
        throw "FAILED Missing plugin version"
      elsif req.query['u'] != @user
        throw "BADUSER"
      elsif not req.query['t']
        throw "BADTIME Missing timestamp"
      elsif req.query['a'] !=
            MD5.hexdigest(MD5.hexdigest(@password) + req.query['t'])
        throw "BADAUTH Invalid auth token"
      end

      @status.successes += 1
      res.body = "OK\n#@session_id\n#@now_playing_url\n#@submit_url\n"

    rescue RuntimeError
      @status.failures += 1
      res.body = "#{$!.message}\n"
    end
  end  # do_GET
end  # AudioscrobblerHandshakeServlet


# Stores a submitted track.  Used by AudioscrobblerSubmitStatus.
class Track
  def initialize(artist=nil, title=nil, length=nil, start_time=nil,
                 album=nil, mbid=nil, track_num=nil, source=nil,
                 rating=nil)
    @artist = artist
    @title = title
    @length = length
    @start_time = start_time
    @album = album
    @mbid = mbid
    @track_num = track_num
    @source = source
    @rating = rating
  end
  attr_accessor :artist, :title, :length, :start_time, :album, :mbid, \
                :track_num, :source, :rating

  def ==(other)
    other.class == Track and @artist == other.artist and
      @title == other.title and @length == other.length and
      @start_time == other.start_time and @album == other.album and
      @mbid == other.mbid and @track_num == other.track_num and
      @source == other.source and @rating == other.rating
  end
end


# Stores the outcome of track submissions received by a
# AudioscrobblerSubmitServlet object.
class AudioscrobblerSubmitStatus
  def initialize
    clear
  end
  attr_accessor :attempts, :successes, :failures, :tracks

  def clear
    @attempts = 0
    @successes = 0
    @failures = 0
    @tracks = []
    self
  end
end


# Implements the track submission portion of the Audioscrobbler protocol.
class AudioscrobblerSubmitServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server, status, session_id)
    @status = status
    @session_id = session_id
  end

  # POST is supposed to be used rather than GET.
  def do_GET(req, res)
    @status.attempts += 1
    @status.failures += 1
    res.body = "FAILED Use POST, not GET\n"
  end

  def do_POST(req, res)
    @status.attempts += 1
    res['Content-Type'] = "text/plain"

    begin
      # Make sure that they authenticated correctly.
      if req.query['s'] != @session_id
        raise "BADSESSION"
      end

      # Handle the track parameters.
      tracks = []
      req.query.each_pair do |k, v|
        if k =~ /^([atiorlbnm])\[(\d+)\]$/
          track = (tracks[$2.to_i] ||= Track.new)
          v = CGI.unescape(v)
          case
          when $1 == 'a': track.artist = v
          when $1 == 't': track.title = v
          when $1 == 'i': track.start_time = v.to_i
          when $1 == 'o': track.source = v
          when $1 == 'r': track.rating = v
          when $1 == 'l': track.length = v.to_i
          when $1 == 'b': track.album = v
          when $1 == 'n': track.track_num = v.to_i
          when $1 == 'm': track.mbid = v
          end
        end
      end

      # Make sure that no data was missing from the submitted tracks.
      tracks.each do |track|
        if not track
          raise "FAILED Missing track"
        elsif not track.artist or not track.title or not track.album or
              not track.mbid or not track.length or not track.start_time or
              not track.track_num or not track.source or not track.rating
          raise "FAILED Missing parameter"
        elsif track.artist.length == 0 or track.title.length == 0 or
              track.length == 0 or track.start_time == 0
          raise "FAILED Empty required parameter"
        end
      end

      # Make sure that we didn't get too few or too many tracks.
      if tracks.length == 0
        raise "FAILED No tracks supplied"
      elsif tracks.length > 10
        raise "FAILED More than 10 tracks supplied"
      end

      # If we get here, then we didn't find any problems.
      @status.tracks += tracks
      @status.successes += 1
      res.body = "OK\n"

    # If we threw an exception, return an error.
    rescue RuntimeError
      @status.failures += 1
      res.body = "#{$!.message}\n"
    end
  end # do_POST
end  # AudioscrobblerSubmitServlet


# Implements the now-playing portion of the Audioscrobbler protocol.
class AudioscrobblerNowPlayingServlet < WEBrick::HTTPServlet::AbstractServlet
  def initialize(server, status, session_id)
    @status = status
    @session_id = session_id
  end

  # POST is supposed to be used rather than GET.
  def do_GET(req, res)
    @status.attempts += 1
    @status.failures += 1
    res.body = "FAILED Use POST, not GET\n"
  end

  def do_POST(req, res)
    @status.attempts += 1
    res['Content-Type'] = "text/plain"

    begin
      # Make sure that they authenticated correctly.
      if req.query['s'] != @session_id
        raise "BADSESSION"
      end

      # Handle the track parameters.
      track = Track.new
      req.query.each_pair do |k, v|
        if %w{a t b l n m}.member? k
          v = CGI.unescape(v)
          case
          when k == 'a': track.artist = v
          when k == 't': track.title = v
          when k == 'b': track.album = v
          when k == 'l': track.length = v.to_i
          when k == 'n': track.track_num = v.to_i
          when k == 'm': track.mbid = v
          end
        end
      end

      # Make sure that no data was missing from the submitted tracks.
      if not track.artist or not track.title or not track.album or
         not track.mbid or not track.length or not track.track_num
        raise "FAILED Missing parameter"
      elsif track.artist.length == 0 or track.title.length == 0 or
            track.length == 0
        raise "FAILED Empty required parameter"
      end

      # If we get here, then we didn't find any problems.
      @status.tracks << track
      @status.successes += 1
      res.body = "OK\n"

    # If we threw an exception, return an error.
    rescue RuntimeError
      @status.failures += 1
      res.body = "#{$!.message}\n"
    end
  end # do_POST
end  # AudioscrobblerNowPlayingServlet


# Regression test for the Audioscrobbler class.
class TestAudioscrobbler < Test::Unit::TestCase
  def test_audioscrobbler
    @handshake_status = AudioscrobblerHandshakeStatus.new
    @submit_status = AudioscrobblerSubmitStatus.new
    @now_playing_status = AudioscrobblerSubmitStatus.new
    # FIXME(derat): Is there some better way to choose a port here?
    @http_port = 16349

    @server_thread = Thread.new do
      s = WEBrick::HTTPServer.new(:BindAddress => "127.0.0.1",
                                  :Port => @http_port,
                                  :Logger => WEBrick::Log.new(
                                      nil, WEBrick::BasicLog::WARN),
                                  :AccessLog => [])
      s.mount("/handshake", AudioscrobblerHandshakeServlet, @handshake_status,
              "username", "password", "sessionid",
              "http://127.0.0.1:#@http_port/submit",
              "http://127.0.0.1:#@http_port/nowplaying")
      s.mount("/submit", AudioscrobblerSubmitServlet, @submit_status,
              "sessionid")
      s.mount("/nowplaying", AudioscrobblerNowPlayingServlet,
              @now_playing_status, "sessionid")
      trap("INT") { s.shutdown }
      s.start
    end

    a = Audioscrobbler.new("username", "password")
    a.client = "tst"
    a.version = "1.1"
    a.handshake_url = "http://127.0.0.1:#@http_port/handshake"
    a.verbose = false

    a.start_submitter_thread

    tracks = []
    tracks.push(Track.new("Beck", "Devil's Haircut", 100, 1128285297,
                          "Odelay", 'abc', 1, 'P', ''))
    tracks.push(Track.new("Faith No More", "Midlife Crisis", 101, 1128285298,
                          "Angel Dust", 'def', 2, 'P', ''))
    tracks.push(Track.new("Hans Zimmer", "Greed", 102, 1128285299,
                          "Broken Arrow", 'ghi', 3, 'P', ''))
    tracks.push(Track.new("Múm", "Sleepswim", 103, 1128285300,
                          "Finally We Are No One", 'jkl', 4, 'P', ''))
    now_playing = []
    now_playing.push(Track.new('Harold Budd', 'Sandtreader', 334, nil,
                               'Lovely Thunder', 'abc', 2))
    now_playing.push(Track.new('Sasha', 'Boileroom', 424, nil,
                               'Airdrawndagger', 'def', 7))

    tracks.each do |t|
      a.enqueue(t.artist, t.title, t.length, t.start_time, t.album, t.mbid,
                t.track_num)
    end

    sleep 0.1  # avoid race condition :-/
    now_playing.each do |t|
      a.report_now_playing(t.artist, t.title, t.length, t.album, t.mbid,
                           t.track_num)
    end

    # FIXME(derat): This is awful.  I should add functionality to
    # Audioscrobbler.enqueue to block until an attempt has been made to
    # submit the just-enqueued track.
    sleep 3

    assert_equal(0, @handshake_status.failures)
    assert(@handshake_status.successes > 0)

    assert_equal(0, @submit_status.failures)
    assert(@submit_status.successes > 0)

    assert_equal(0, @now_playing_status.failures)
    assert_equal(2, @now_playing_status.successes)

    assert_equal(tracks, @submit_status.tracks)
    assert_equal(now_playing, @now_playing_status.tracks)
  end  # test_audioscrobbler

  # Test that we don't crash when the handshake returns an unparseable
  # now-playing URL.
  def test_broken_url
    @handshake_status = AudioscrobblerHandshakeStatus.new
    @submit_status = AudioscrobblerSubmitStatus.new
    @now_playing_status = AudioscrobblerSubmitStatus.new
    # FIXME(derat): Quite mortifying that I'm just using a different port
    # from the previous tests instead of killing off the old server.
    @http_port = 16350

    @server_thread = Thread.new do
      s = WEBrick::HTTPServer.new(:BindAddress => "127.0.0.1",
                                  :Port => @http_port,
                                  :Logger => WEBrick::Log.new(
                                      nil, WEBrick::BasicLog::WARN),
                                  :AccessLog => [])
      # Use garbage for the submit and now-playing URLs.
      s.mount("/handshake", AudioscrobblerHandshakeServlet, @handshake_status,
              "username", "password", "sessionid",
              "hch094h09h9 htnhstn",  # submit
              "gcrlhc g g890")  # now-playing
      trap("INT") { s.shutdown }
      s.start
    end

    a = Audioscrobbler.new("username", "password")
    a.client = "tst"
    a.version = "1.1"
    a.handshake_url = "http://127.0.0.1:#@http_port/handshake"
    a.verbose = false
    a.start_submitter_thread

    assert(!a.report_now_playing('artist', 'title', 100, 'album', 'mbid', 1))
  end  # test_broken_url
end  # TestAudioscrobbler
