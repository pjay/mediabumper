require 'rubygems'
SPEC = Gem::Specification.new do |s|
  s.name          = "audioscrobbler"
  s.version       = "0.1.0"
  s.author        = "Daniel Erat"
  s.email         = "dan-ruby@erat.org"
  s.homepage      = "http://www.erat.org/ruby/"
  s.platform      = Gem::Platform::RUBY
  s.summary       = "Library to submit music playlists to Last.fm"
  candidates      = Dir.glob("{*,{lib,test}/*}")
  s.files         = candidates.delete_if {|i| i =~ /CVS/ }
  s.require_path  = "lib"
  s.autorequire   = "audioscrobbler"
  s.test_files    = Dir.glob("test/test_{audioscrobbler,queue}.rb")
  s.has_rdoc      = true
end
