class FileController < ApplicationController
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
    if params[:q]
      # Translate search query to FQL (see Ferret doc)
      query = params[:q].strip.split(/ +/).map { |term| term << '~.5' }.join ' '
      
      # FIXME: upcoming release of acts_as_ferret will include a
      #        MediaFile#total_hits method, use it when available
      total_hits = MediaFile.ferret_index.search(query).total_hits
      @search_pages = Paginator.new self, total_hits, SEARCH_PAGINATION_SIZE, params[:p]
      
      begin
        # Catch syntax errors in FQL
        @files = MediaFile.find_by_contents query,
          :limit => @search_pages.items_per_page,
          :offset => @search_pages.current.offset
      rescue
        flash[:error] = "Error executing the query, please try again."
        redirect_to :action => 'search'
      end
    end
  end
  
  def random
    limit = params[:s] || session[:random_selection_size] || 20
    session[:random_selection_size] = limit
    @files = MediaFile.find(:all, :limit => limit, :order => 'RAND()')
  end
  
  def stream
    if params[:id]
      file = MediaFile.find(params[:id])
      path = file.path
    elsif params[:r] && params[:p]
      repository = Repository.find(params[:r])
      path = File.join(repository.path, params[:p])
    end
    send_file path, :type => 'audio/mpeg', :disposition => 'inline'
  end
end
