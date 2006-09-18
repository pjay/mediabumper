#!/usr/bin/env ruby

module Mediabumper
  # This is an ID3 library abstraction class to be independant of the
  # implementation available. The implementation should be chosen during the
  # initialization of this class.
  class Id3lib
    attr_accessor :title, :artist, :album, :year, :genre, :comments
    
    def initialize
    
    end
  end
end
