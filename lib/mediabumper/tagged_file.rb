module Mediabumper
  # ID3 tags parsing library abstraction
  class TaggedFile
    def initialize(path)
      af = ID3::AudioFile.new path
      
      tags1 = af.tagID3v1
      tags2 = af.tagID3v2
      
      ['title', 'artist', 'album', 'year'].each do |key|
        value = begin
          tags2[key.upcase]['text'] || tags1[key.upcase]
        rescue
        end
        
        instance_variable_set(:"@#{key}", value)
        self.class.send :attr_reader, :"#{key}"
      end
    end
  end
end
