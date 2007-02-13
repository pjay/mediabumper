namespace :mediabumper do
  desc "Starts the indexing of all repositories"
  task :index => :environment do
    Mediabumper::Indexer.start
  end
end
