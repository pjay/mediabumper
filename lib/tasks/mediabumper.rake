namespace :mediabumper do
  desc "Starts the indexing of all repositories"
  task :index => :environment do
    Repository.find(:all).each do |r|
      Mediabumper::Indexer.new(r).start
    end

    # FIXME: there should be a faster way :)
    MediaFile.find(:all).each do |mf|
      mf.destroy unless File.exists? mf.path
    end

    # FIXME: purge other models such as albums, artists and songs
  end
end
