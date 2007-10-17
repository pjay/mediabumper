#!/usr/bin/ruby -w
#
# = Name
# TestPlayedTrack, TestSubmissionQueue
#
# == Description
# This file contains unit tests for the PlayedTrack and SubmissionQueue
# components of the Audioscrobbler class.
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
require 'tempfile'
require 'test/unit'

class Audioscrobbler
  class SubmissionQueue
    class TestPlayedTrack < Test::Unit::TestCase
      def test_members
        t = PlayedTrack.new(
          'Cylob', 'Stomping FM', 100, 1128285297, 'Lobster Tracks',
          'abc', 3)
        assert_equal('Cylob', t.artist)
        assert_equal('Stomping FM', t.title)
        assert_equal(100, t.length)
        assert_equal(1128285297, t.start_time)
        assert_equal('Lobster Tracks', t.album)
        assert_equal('abc', t.mbid)
        assert_equal('3', t.track_num)
      end

      def test_empty_members
        t = PlayedTrack.new(
          'Cylob', 'Stomping FM', 200, 1128285298, nil, nil, nil)
        assert_equal('Cylob', t.artist)
        assert_equal('Stomping FM', t.title)
        assert_equal(200, t.length)
        assert_equal(1128285298, t.start_time)
        assert_equal('', t.album)
        assert_equal('', t.mbid)
        assert_equal('', t.track_num)
      end

      def test_serialization
        t = PlayedTrack.new(
          'Katamari Damacy', 'WANDA WANDA', 100, 1128285297, 'OST', 'blah', 5)
        assert_equal(t,
          PlayedTrack.deserialize(t.serialize))

        t = PlayedTrack.new(
          'Def Leppard', 'Photograph', 100, 1128285297, nil, 'blah', 6)
        assert_equal(t,
          PlayedTrack.deserialize(t.serialize))
      end
    end  # class TestPlayedTrack
  end  # class SubmissionQueue

  class TestSubmissionQueue < Test::Unit::TestCase
    def setup
      file = Tempfile.new('audioscrobbler_test_queue')
      @filename = file.path
      file.close
    end

    def test_it
      q = SubmissionQueue.new(@filename)

      q.append('Kraftwerk', 'Computer Love', 100, 1128285297,
        'Computer World', nil)
      q.append('Iron Maiden', 'Aces High', 100, 1128285297,
        'Powerslave', nil)
      q.append('Herbie Hancock', 'Cantaloupe Island', 100, 1128285297,
        'Empyrean Isles', nil)

      # Create a new queue, pointing at the same backup file.
      q = SubmissionQueue.new(@filename)

      tracks = q.peek(1)
      assert_equal(1, tracks.length)
      assert_equal('Kraftwerk', tracks[0].artist)

      q.delete(1)
      tracks = q.peek(5)
      assert_equal(2, tracks.length)
      assert_equal('Iron Maiden', tracks[0].artist)
      assert_equal('Herbie Hancock', tracks[1].artist)
    end

    def teardown
      File.delete(@filename) if File.exists?(@filename)
    end
  end  # class TestSubmissionQueue
end  # class AudioScrobbler
