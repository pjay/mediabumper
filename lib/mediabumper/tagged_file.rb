module Mediabumper
  # ID3 tags parsing library abstraction
  class TaggedFile
    def initialize(path)
      Mp3Info.open(path) do |mp3info|
        [:title, :artist, :album, :year].each do |key|
          instance_variable_set :"@#{key}", mp3info.tag.send(key)
          self.class.send :attr_reader, :"#{key}"
        end
      end
    end
  end
end
