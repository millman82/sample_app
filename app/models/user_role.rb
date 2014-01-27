# == Schema Information
#
# Table name: user_roles
#
#  user_id :integer
#  role_id :integer
#

class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  # attr_accessible :title, :body
end
