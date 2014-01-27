# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  email           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  password_digest :string(255)
#  remember_token  :string(255)
#

class User < ActiveRecord::Base
  has_secure_password
  has_many :user_roles
  has_many :roles, :through => :user_roles
  has_many :microposts, :dependent => :destroy

  attr_accessible :email, :name, :password, :password_confirmation
  
  before_save { |user| user.email = email.downcase }
  before_save :create_remember_token
  before_create :set_default_role
  
  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  
  validates :name,  :presence   => true,
                    :length     => { :maximum => 50 }
  validates :email, :presence   => true,
                    :format     => { :with => email_regex },
                    :uniqueness => { :case_sensitive => false }
  validates :password, :presence => true,
                       :confirmation => true,
                       :length => { :within => 6..40 }
  validates :password_confirmation, :presence => true
  
  def has_role?(role_sym)
    roles.any? { |r| r.name.underscore.to_sym == role_sym }
  end
  
  private
  
    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end
    
    def set_default_role
      if self.role_ids.empty?
        self.role_ids = [1]
      end
    end

end
