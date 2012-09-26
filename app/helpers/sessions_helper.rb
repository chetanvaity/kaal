module SessionsHelper
  
  def sign_in(user)
    cookies.permanent[:remember_token] = user.remember_token
    self.current_user = user
  end
  
  #Set method
  def current_user=(user)
    @current_user = user
  end
  
  #get method
  def current_user
    @current_user ||= User.find_by_remember_token(cookies[:remember_token])
  end
  
  def signed_in?
    !current_user.nil?
  end
  
  def destroy
    sign_out
    redirect_to root_path
  end
  
  def sign_out
    self.current_user = nil
    cookies.delete(:remember_token)
  end
  
  def authenticate_user!
    if !signed_in?
      flash[:error] = 'You need to sign in before accessing this page!'
      redirect_to root_path
      #Instead of this , we may need to create a separate login page and redirect over there.
    end
  end   
  
  def current_user?(user)
    user == self.current_user
  end
  
  #
  # Used to protect certain pages which user can access only after login.
  #
  def signing_is_must
    if !signed_in?
      store_location()
      flash[:notice] = 'Please log in before proceeding further!'
      redirect_to extlogin_path
    end
  end
  
  #
  # HElper methods for friendly url forwrding during login
  #
  def store_location
    session[:return_to] = request.url
  end
  
  def clear_stored_location
    session.delete(:return_to)
  end
  
  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_stored_location
  end
  # ---------------------------------------
  
end
