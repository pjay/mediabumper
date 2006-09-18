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
      
      begin
        # Catch syntax errors in FQL
        @files = MediaFile.find_by_contents(query)
      rescue
        flash[:error] = "Error executing the query, please try again."
        redirect_to :action => 'search'
      end
    end
  end
  
  def stream
    if params[:id]
      file = MediaFile.find(params[:id])
      path = file.path
    elsif params[:r] && params[:p]
      repository = Repository.find(params[:r])
      path = File.join(repository.path, params[:p])
    end
    send_file file.path, :type => 'audio/mpeg', :disposition => 'inline'
  end
end
