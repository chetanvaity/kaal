class SessionsController < ApplicationController
  
  before_filter :authenticate_user!, :except => [:create, :failure]
  protect_from_forgery :except => :create     # see https://github.com/intridea/omniauth/issues/203

  
  def new
  end
  
  def create
    authservice = params[:service]
    
    if authservice.nil?
      flash[:error] = 'No authentication service recognized'
      redirect_to root_path # we may redirect to separate signin page if we have one
    end
    
    # get the full hash from omniauth
    omniauth = request.env['omniauth.auth']
    if (authservice == "google" || authservice == "facebook") && omniauth.nil?
      flash[:error] = authservice + ' authentication service did not work properly.'
      redirect_to root_path # we may redirect to separate signin page if we have one
    end
    
    # create a new hash
    @authhash = Hash.new
    
    if authservice == "google"
      omniauth['info']['email'] ? @authhash[:email] =  omniauth['info']['email'] : @authhash[:email] = ''
      omniauth['info']['name'] ? @authhash[:name] =  omniauth['info']['name'] : @authhash[:name] = ''
      omniauth['uid'] ? @authhash[:uid] = omniauth['uid'].to_s : @authhash[:uid] = ''
      omniauth['provider'] ? @authhash[:provider] = omniauth['provider'] : @authhash[:provider] = ''
    elsif authservice == "facebook"
      raise request.env["omniauth.auth"].to_yaml
    end
    
    if @authhash[:uid] == '' || @authhash[:provider] == '' || @authhash[:email] == ''
      flash[:error] =  'Error while authenticating via ' + authservice.capitalize + '. The service returned invalid data.'
      redirect_to root_path # we may redirect to separate signin page if we have one
    end
    
    #
    # OK ...let's now check user availability and if already signed in , etc checks
    #
    auth_user = User.find_by_authprovider_and_authuid(@authhash[:provider], @authhash[:uid])
    if auth_user
      # signin existing user
      sign_in(auth_user)
      redirect_to root_url
    else
      # create new user and sign in him
      new_user = User.new
      new_user.email = @authhash[:email]
      new_user.name = @authhash[:name]
      new_user.authprovider = @authhash[:provider]
      new_user.authuid = @authhash[:uid]
      if new_user.save
        sign_in new_user
        redirect_to root_path
      else
        flash[:error] = "Error while creating user for emailid=" + @authhash[:email] + " after " + @authhash[:provider] + "-authentication." 
      end
    end

  end
  
  def destroy
    sign_out
    redirect_to root_path
  end
  
  # Auth callback: failure
  def failure
    flash[:error] = 'There was an error at the remote authentication service. You have not been signed in.'
    redirect_to root_url
  end
  
end
