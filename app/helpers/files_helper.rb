module FilesHelper
  def files_in(repository, relative_path)
    path = repository.path
    if relative_path && !relative_path.empty?
      path = File.join(path, relative_path)
    end
    
    Dir.entries(path).delete_if { |d| d =~ /^\./ }
  end
  
  def parent_dir(path)
    path.split(File::SEPARATOR)[0..-2]
  end
end
