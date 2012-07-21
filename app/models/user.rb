class User < ActiveRecord::Base
  
  attr_accessible :name, :email, :authuid, :authprovider
  
  before_save { |user| user.email = email.downcase }
  before_save :create_remember_token
  
  validates :name, presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  
  # We need unique email w.r.t. a given auth-provider.
  # It means the same email id may get used by multiple auth-providers, and it is valid.
  # For example, I may use same email id for google as well as facebook to login.
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },  :uniqueness => {case_sensitive: false, :scope => :authprovider}
  
  
  private
    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end

end
