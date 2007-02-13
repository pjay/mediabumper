module Mediabumper
  class Indexer
    class << self
      def start
        Repository.find(:all).each do |r|
          dirs = [r.path]
          
          dirs.each do |dir|
            begin
              Dir.foreach(dir) do |f|
                next if f == '.' or f == '..'

                fullpath = File.join(dir, f)

                if File.directory? fullpath
                  dirs << fullpath
                else
                  MediaFile.index(fullpath, r)
                end
              end
            rescue Exception => e
              puts "ERROR: #{e.message}"
              raise e
            end
          end
        end
        
        # FIXME: there should be a faster way :)
        MediaFile.find(:all).each do |mf|
          mf.destroy unless File.exists? mf.path
        end
      end
    end
  end
end