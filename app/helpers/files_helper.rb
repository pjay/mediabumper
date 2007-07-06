module FilesHelper
  # Returns an array of files present in repository and relative_path specified.
  # No relative path means the repository root. All files beginning with a dot
  # are suppressed from the returned array as they usually are hidden or system
  # files.
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
  
  # Returns HTML code to display a directory entry which will depend on its
  # type.
  def directory_entry(repository, relative_path, file)
    path = relative_path ? File.join(repository.path, relative_path, file) : File.join(repository.path, file)
    
    if File.directory? path
      link_to h(file), :r => repository, :p => relative_path ? File.join(relative_path, file) : file
    elsif File.file?(path) && MediaFile::EXTENSIONS.include?(File.extname(path))
      real_relative_path = relative_path ? File.join(relative_path, file) : file
      link_to_stream h(file), :r => repository, :p => real_relative_path
    else
      h(file)
    end
  end
  
  # Given a repository and a path relative to the repository root, returns a
  # breadcrumb-like filesystem navigation with each directory being a link to
  # browse its content.
  def path_with_browse_links(repository, relative_path)
    current_path, links = Array.new, Array.new
    
    links << link_to(h(@repository.name), repository_path(:r => @repository.id))
    return links unless relative_path
    
    relative_path.split(File::SEPARATOR).each do |entry|
      current_path << entry
      links << link_to(h(entry), browse_path(:r => repository, :p => current_path.join(File::SEPARATOR)))
    end
    
    links.join(" #{File::SEPARATOR} ")
  end
end
