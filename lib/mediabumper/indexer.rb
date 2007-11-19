module Mediabumper
  class Indexer
    def initialize(repository, path = nil)
      @repository = repository
      @path       = path || @repository.path
    end

    def start
      dirs = [@path]

      while dir = dirs.shift
        Dir.foreach(dir) do |f|
          next if f.index('.') == 0  # Skip files/dirs beginning with a dot

          fullpath = File.join(dir, f)

          if File.directory? fullpath
            dirs << fullpath
          else
            MediaFile.index(fullpath, @repository)
          end
        end
      end
    end
  end
end
