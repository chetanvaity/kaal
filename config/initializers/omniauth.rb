Rails.application.config.middleware.use OmniAuth::Builder do
  require 'openid/store/filesystem'

  #Google Auth Strategy
  provider :open_id, :store => OpenID::Store::Filesystem.new('/tmp'), :name => 'google', :identifier => 'https://www.google.com/accounts/o8/id', :require => 'omniauth-openid'
  
  #Facebook Auth Strategy
  #provider :facebook, 'APP_ID', 'APP_SECRET'
  provider :facebook, '339152742831452', 'f5383af93f971a513bbb6ed1ceb72058'

end
