class FilesController < ApplicationController
  def browse
    if params[:r]
      # FIXME: add path sanitization
      @repository    = Repository.find(params[:r])
      @relative_path = params[:p]
    else
      @repositories = Repository.find :all
    end
  end
  
  def search
    unless params[:q].blank?
      # Translate search query to FQL fuzzy search (see Ferret doc)
      query = params[:q].strip.split(/ +/).map { |term| term << '~.5' }.join ' '
      @files = MediaFile.paginate_by_contents query, :page => (params[:page] || 1)
    else
      flash[:error] = "Please enter at least one search term."
    end
  end
  
  def random
    limit = params[:s] || session[:random_selection_size] || '20'
    session[:random_selection_size] = limit
    @files = MediaFile.find(:all, :limit => limit, :order => 'RAND()')
  end
  
  def stream
    if params[:id]
      file = MediaFile.find(params[:id])
      path = file.path
      
      if logged_in?
        Playback.create :user => current_user, :media_file => file
      end
    elsif params[:r] && params[:p]
      repository = Repository.find(params[:r])
      path = File.join(repository.path, params[:p])
    end
    
    send_file path, :type => 'audio/mpeg', :disposition => 'inline'
  end
end
