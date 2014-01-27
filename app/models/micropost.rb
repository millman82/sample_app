# == Schema Information
#
# Table name: microposts
#
#  id         :integer          not null, primary key
#  content    :string(255)
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Micropost < ActiveRecord::Base
  belongs_to :user
  
  attr_accessible :content
  
  default_scope order: 'microposts.created_at DESC'
end
