require 'spec_helper'

describe UsersController do
  render_views
  
  describe "GET 'index'" do
    describe "for non-signed-in users" do
      it "should redirect" do
        get :index
        response.should redirect_to(signin_path)
      end
    end
    
    describe "for signed-in users" do
      before(:each) do
        @user = test_sign_in(FactoryGirl.create(:user))
        FactoryGirl.create(:user, :email => "another@example.com")
        FactoryGirl.create(:user, :email => "another@example.net")
      end
      
      it "should be successful" do
        get :index
        response.should be_success
      end
      
      it "should have the right title" do
        get :index
        response.should have_selector('title', :content => "All users")
      end
      
      describe "pagination" do
        before(:all) { 30.times { FactoryGirl.create(:user) } }
        after(:all)  { User.delete_all }
        
        it "should paginate users" do
          get :index
          response.should have_selector('div.pagination')
          response.should have_selector('li.disabled a', content: "Previous")
          response.should have_selector('a', href: "/users?page=2", content: "2")
          response.should have_selector('a', href: "/users?page=2", content: "Next")
        end
        
        it "should list each user" do
          get :index
          User.paginate(page: 1).each do |user|
            response.should have_selector('li', content: user.name)
          end
        end
      end
    end
  end
  
  describe "GET 'show'" do
    let(:user) { FactoryGirl.create(:user) }
    
    it "should be successful" do
      get :show, :id => user.id
      response.should be_success
    end
    
    it "should find the right user" do
      get :show, :id => user
      assigns(:user).should == user
    end
    
    it "should have the right title" do
      get :show, :id => user
      response.should have_selector('title', :content => user.name)
    end
    
    it "should have the user's name" do
      get :show, :id => user
      response.should have_selector('h1', :content => user.name)
    end
    
    it "should have a profile image" do
      get :show, :id => user
      response.should have_selector('h1>img', :class => "gravatar")
    end
  end
  
  describe "GET 'new'" do
    it "returns http success" do
      get :new
      response.should be_success
    end
    
    it "should have the right title" do
      get :new
      response.should have_selector("title", :content => "Sign up")
    end
  end
  
  describe "POST 'create'" do
    describe "failure" do
      before(:each) do 
        @attr = { :name => "", :email => "", :password => "", :password_confirmation => "" }
      end
      
      it "should have the right title" do
        post :create, :user => @attr
        response.should have_selector('title', :content => "Sign up")
      end
      
      it "should render a 'new' page" do
        post :create, :user => @attr
        response.should render_template('new')
      end
        
      it "should not create a user" do
        lambda do
          post :create, :user => @attr
        end.should_not change(User, :count)
      end
    end
    
    describe "success" do
      before(:each) do
        @attr = { :name => "New User", :email => "user@example.com", :password => "foobar", :password_confirmation => "foobar" }
      end
      
      it "should create a user" do
        lambda do
          post :create, :user => @attr
        end.should change(User, :count).by(1)
      end
      
      it "should redirect to the user show page" do
        post :create, :user => @attr
        response.should redirect_to(user_path(assigns(:user)))
      end
      
      it "should have a welcome message" do
        post :create, :user => @attr
        flash[:success].should =~ /welcome to the sample app/i
      end
      
      it "should sign the user in" do
        post :create, :user => @attr
        controller.should be_signed_in
      end
    end
  end
  
  describe "GET 'edit'" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
    end
    
    it "should be successful" do
      get :edit, :id => @user
      response.should be_success
    end
    
    it "should have the right title" do
      get :edit, :id => @user
      response.should have_selector('title', :content => "Edit user")
    end
    
    it "should have a link to change the Gravatar" do
      get :edit, :id => @user
      response.should have_selector('a', :href => 'http://gravatar.com/emails',
                                         :content => "change")
    end
  end
  
  describe "PUT 'update'" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      test_sign_in(@user)
    end
    
    describe "failure" do
      before(:each) do
        @attr = { :name => "", :email => "", :password => "", :password_confirmation => "" }
      end
      
      it "should render the 'edit' page" do
        put :update, :id => @user, :user => @attr
        response.should render_template('edit')
      end
      
      it "should have the right title" do
        put :update, :id => @user, :user => @attr
        response.should have_selector('title', :content => "Edit user")
      end
    end
    
    describe "success" do
      before(:each) do
        @attr = { :name => "New Name", :email => "user@example.org", :password => "barbaz", :password_confirmation => "barbaz" }
      end
      
      it "should change the user's attributes" do
        put :update, :id => @user, :user => @attr
        user = assigns(:user)
        @user.reload
        @user.name.should == user.name
        @user.email.should == user.email
        @user.password_digest.should == user.password_digest
      end
      
      it "should have a flash message" do
        put :update, :id => @user, :user => @attr
        flash[:success].should =~ /updated/
      end
    end
  end
  
  describe "authentication of edit/update actions" do
    before(:each) do
      @user = FactoryGirl.create(:user)
    end
    
    describe "for non-signed-in-users" do
      it "should deny access to 'edit'" do
        get :edit, :id => @user
        response.should redirect_to(signin_path)
        flash[:notice].should =~ /sign in/i
      end
    
      it "should deny access to 'update'" do
        put :update, :id => @user, :user => {}
        response.should redirect_to(signin_path)
      end
    end
    
    describe "for signed-in users" do
      before(:each) do
        wrong_user = FactoryGirl.create(:user, :email => "user@example.net")
        test_sign_in(wrong_user)
      end
      
      it "should require matching users for 'edit'" do
        get :edit, :id => @user
        response.should redirect_to(root_path)
      end
      
      it "should require matching users for 'update'" do
        put :update, :id => @user, :user => {}
        response.should redirect_to(root_path)
      end
    end
  end

end
