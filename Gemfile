source 'http://rubygems.org'

gem 'rails', '3.2.10'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "  ~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier', ">= 1.0.3"
  gem 'therubyracer'
end

gem 'jquery-rails'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

gem 'haml'

gem 'nokogiri'

#group :development, :test do
#  gem 'ruby-debug19'
#end

gem 'mysql2', '0.3.11'
gem 'hashery', '2.0.0'

gem 'debugger'
gem 'bootstrap-sass', '2.0.0'
gem 'awesome_nested_fields'
gem 'dynamic_form'
gem 'PageRankr', '3.2.1'

#
# for default auth mechanism
#
gem 'bcrypt-ruby', '3.0.1'

#
# For third party authentication
#
gem 'omniauth'
gem 'omniauth-openid' #Google
gem 'omniauth-facebook' #Facebook

# 
# To integrate with search server "Solr" which works on top of 'lucene'
# 
gem 'sunspot_rails', '~> 1.3.0'
gem 'sunspot_solr'  #to control local solr instance
gem 'progress_bar'

#
# For google analytics
#
group :production do
  gem 'rack-google-analytics', :require => 'rack/google-analytics'
end 


# For Pagination
gem 'kaminari'

#
# For AMol's vmplayer problem:
# Acces to webpages from host machine was very very slow, not usable. Following link says that it is
# a webrick issue and suggests to use 'thin' or 'mongrel'. Amol picked up 'thin' as 'mongrel'
# did not install on his machine for unknown reasons.
# http://superuser.com/questions/183375/ubuntu-in-virtualbox-webrick-web-server-very-slow-when-using-local-ip-address
#
# With 'thin', you need to say 'thin start' instead of 'rails server'.
#
group :test, :development do
  gem 'thin'
end

# For easy authorization
gem 'cancan'

#To display preview of timeline
#https://rubygems.org/gems/prettyphoto-rails
gem 'prettyphoto-rails'