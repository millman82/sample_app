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

require 'spec_helper'

describe User do
  
  before(:each) do
    @attr = { 
      :name=>"Example User",
      :email=>"user@example.com",
      :password => "foobar",
      :password_confirmation => "foobar"
    }
  end
  
  it "should create a new instance given a valid attribute" do
    User.create!(@attr)
  end
  
  it "should require a name" do
    no_name_user = User.new(@attr.merge(:name => ""))
    no_name_user.should_not be_valid
  end
  
  it "should require a email" do
    no_email_user = User.new(@attr.merge(:email => ""))
    no_email_user.should_not be_valid
  end
  
  it "should reject names that are too long" do
    long_name = "a" * 51
    long_name_user = User.new(@attr.merge(:name => long_name_user))
    long_name_user.should_not be_valid
  end
  
  it "should accept valid email addresses" do
    addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
    addresses.each do |address|
      valid_email_user = User.new(@attr.merge(:email => address))
      valid_email_user.should be_valid
    end
  end
  
  it "should reject invalid email addresses" do
    addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
    addresses.each do |address|
      invalid_email_user = User.new(@attr.merge(:email => address))
      invalid_email_user.should_not be_valid
    end
  end
  
  it "should reject duplicate email addresses" do
    User.create!(@attr)
    user_with_duplicate_email = User.new(@attr)
    user_with_duplicate_email.should_not be_valid
  end
  
  it "should reject email addresses identical up to case" do
    upcased_email = @attr[:email].upcase
    User.create!(@attr.merge(:email => upcased_email))
    user_with_duplicate_email = User.new(@attr)
    user_with_duplicate_email.should_not be_valid
  end
  
  describe "passwords" do
    
    before(:each) do
      @user = User.new(@attr)
    end
    
    subject { @user }
    
    it "should have a password attribute" do
      should respond_to(:password)
    end
    
    it "should have a password confirmation attribute" do
      should respond_to(:password_confirmation)
    end
    
    it "should have a password digest attribute" do
      should respond_to(:password_digest)
    end
    
    it "should have a remember_token attribute" do
      should respond_to(:remember_token)
    end
    
    it "should have an authenticate method" do
      should respond_to(:authenticate)
    end
    
    describe "remember token" do
      before { @user.save }
      its(:remember_token) { should_not be_blank }
    end
  end
  
  describe "password validations" do
    it "should require a password" do
      User.new(@attr.merge(:password => "", :password_confirmation => "")).
        should_not be_valid
    end
    
    it "should require a matching password confirmation" do
      User.new(@attr.merge(:password_confirmation => "invalid")).
        should_not be_valid
    end
    
    it "should reject short passwords" do
      short = "a" * 5
      hash = @attr.merge(:password => short, :password_confirmation => short)
      User.new(hash).should_not be_valid
    end
    
    it "should reject long passwords" do
      long = "a" * 41
      hash = @attr.merge(:password => long, :password_confirmation => long)
      User.new(hash).should_not be_valid
    end
  end
  
  describe "roles" do
    before(:each) do
      @user = User.create!(@attr)
    end
    
    it "should respond to has role" do
      @user.should respond_to(:has_role?)
    end
    
    it "should be a user by default" do
      @user.has_role?(:user).should be_true
    end
    
    it "should not be an admin by default" do
      @user.has_role?(:admin).should be_false
    end
    
    it "should be convertable to an admin" do
      @user.role_ids = [2]
      @user.has_role?(:user).should be_false
      @user.has_role?(:admin).should be_true
    end
  end
  
  describe "micropost associations" do
    before { @user = User.create(@attr) }
    let!(:older_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago)
    end
    let!(:newer_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.hour.ago)
    end
    
    subject { @user }
    
    it { should respond_to(:microposts) }
    
    it "should have the right microposts in the right order" do
      @user.microposts.should == [newer_micropost, older_micropost]
    end
    
    it "should destroy associated microposts" do
      microposts = @user.microposts.dup
      @user.destroy
      microposts.should_not be_empty
      microposts.each do |micropost|
        Micropost.find_by_id(micropost.id).should be_nil
      end
    end
    
    describe "status feed" do
      it "should have a feed" do
        @user.should respond_to(:feed)
      end
      
      it "should include the user's microposts" do
        @user.feed.should include(older_micropost)
        @user.feed.should include(newer_micropost)
      end
      
      it "should not include a different user's microposts" do
        mp3 = FactoryGirl.create(:micropost, user: FactoryGirl.create(:user))
        @user.feed.should_not include(mp3)
      end
      
      it "should include the microposts of followed users" do
        followed = FactoryGirl.create(:user)
        mp3 = FactoryGirl.create(:micropost, user: followed)
        @user.follow!(followed)
        @user.feed.should include(mp3)
      end
    end
  end
  
  describe "relationships" do
    before { @user = User.create(@attr) }
    
    subject { @user }
    
    it { should respond_to(:relationships) }
    it { should respond_to(:followed_users) }
    it { should respond_to(:reverse_relationships) }
    it { should respond_to(:followers) }
    it { should respond_to(:following?) }
    it { should respond_to(:follow!) }
    it { should respond_to(:unfollow!) }
    
    describe "following" do
      let(:other_user) { FactoryGirl.create(:user) }
      before do
        @user.save
        @user.follow!(other_user)
      end
      
      it { should be_following(other_user) }
      its(:followed_users) { should include(other_user) }
      
      describe "followed user" do
        subject { other_user }
        its(:followers) { should include(@user) }
      end
      
      describe "and unfollowing" do
        before { @user.unfollow!(other_user) }
        
        it { should_not be_following(other_user) }
        its(:followed_users) { should_not include(other_user) }
      end
    end
  end
  
end
