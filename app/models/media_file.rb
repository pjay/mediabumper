class MediaFile < ActiveRecord::Base
  acts_as_ferret({}, { :analyzer => Ferret::Analysis::LetterAnalyzer.new })
  
  belongs_to :repository
  
  EXTENSIONS = ['.mp3'].freeze
  
  class << self
    def index(path, repository)
      if self::EXTENSIONS.include? File.extname(path)
        relative_path = path.sub /^#{repository.path}#{File::SEPARATOR}/, ''
        find_or_create_by_relative_path_and_repository_id(relative_path, repository.id)
      end
    end
    
    def recent(limit)
      find(:all, :order => 'created_at DESC', :limit => limit)
    end
  end
  
  def split_relative_path
    relative_path.split File::SEPARATOR
  end
  
  def path
    File.join(repository.path, relative_path)
  end
  
  def basename
    File.basename(path)
  end
end
