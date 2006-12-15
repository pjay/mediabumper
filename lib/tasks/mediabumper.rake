namespace :mediabumper do
  desc "Starts the indexing of all repositories"
  task :index => :environment do
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
        end
      end
    end
  end
end
