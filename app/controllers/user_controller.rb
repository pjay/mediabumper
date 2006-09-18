class UserController < ApplicationController
  before_filter :login_required, :except => [:login, :signup]
  
  # say something nice, you goof!  something sweet.
  def index
    redirect_to(:action => 'login') unless logged_in?
    redirect_to(:action => 'profile')
  end

  def signup
    @user = User.new(params[:user])
    return unless request.post?
    @user.save!
    self.current_user = @user
    redirect_back_or_default(:controller => 'user', :action => 'index')
    flash[:notice] = "Thanks for signing up!"
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if current_user
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(:controller => 'user', :action => 'index')
      flash[:notice] = "Logged in successfully"
    end
  end

  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => 'user', :action => 'index')
  end
  
  def profile
    
  end
end
