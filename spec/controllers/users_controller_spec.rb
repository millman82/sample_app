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
      
      it "should have delete links for admins" do
        @user.role_ids = [2]
        other_user = User.all.second
        get :index
        response.should have_selector('a', href: user_path(other_user),
                                           content: "delete")
      end
      
      it "should not have delete links for non-admins" do
        other_user = User.all.second
        get :index
        response.should_not have_selector('a', href: user_path(other_user),
                                           content: "delete")
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
    
    it "should show the user's microposts" do
      mp1 = FactoryGirl.create(:micropost, user: user, content: "Foo bar")
      mp2 = FactoryGirl.create(:micropost, user: user, content: "Baz quux")
      get :show, id: user
      response.should have_selector('span.content', content: mp1.content)
      response.should have_selector('span.content', content: mp2.content)
      response.should have_selector('h3', content: user.microposts.count.to_s)
    end
    
    it "should paginate microposts" do
      35.times { FactoryGirl.create(:micropost, user: user, content: "foo") }
      get :show, id: user
      response.should have_selector('div.pagination')
    end
    
    describe "when signed in as another user" do
      it "should be successful" do
        test_sign_in(FactoryGirl.create(:user))
        get :show, id: user
        response.should be_success
      end
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
  
  describe "DELETE 'destroy'" do
    before(:each) do
      @user = FactoryGirl.create(:user)
    end
    
    describe "as a non-signed-in user" do
      it "should deny access" do
        delete :destroy, :id => @user
        response.should redirect_to(signin_path)
      end
    end
    
    describe "as non-admin user" do
      it "should protect the action" do
        test_sign_in(@user)
        delete :destroy, :id => @user
        response.should redirect_to(root_path)
      end
    end
    
    describe "as an admin user" do
      before(:each) do
        @admin = FactoryGirl.create(:user, email: "admin@example.com", role_ids: [2])
        test_sign_in(@admin)
      end
      
      it "should destroy the user" do
        lambda do
          delete :destroy, :id => @user
        end.should change(User, :count).by(-1)
      end
      
      it "should redirect to the users page" do
        delete :destroy, :id => @user
        flash[:success].should =~ /destroyed/i
        response.should redirect_to(users_path)
      end
      
      it "should not be able to destroy itself" do
        lambda do
          delete :destroy, :id => @admin
        end.should_not change(User, :count)
      end
    end
  end
  
  describe "follow pages" do
    describe "when not signed in" do
      it "should protect 'following'" do
        get :following, id: 1
        response.should redirect_to(signin_path)
      end
      
      it "should protect 'followers'" do
        get :followers, id: 1
        response.should redirect_to(signin_path)
      end
    end
    
    describe "when signed in" do
      let(:user) { FactoryGirl.create(:user) }
      let(:other_user) { FactoryGirl.create(:user) }
      
      before do
        test_sign_in(user)
        user.follow!(other_user)
      end
      
      it "should show user following" do
        get :following, id: user
        response.should have_selector('a', href: user_path(other_user), content: other_user.name)
      end
      
      it "should show user followers" do
        get :followers, id: other_user
        response.should have_selector('a', href: user_path(user), content: user.name)
      end
    end
  end

end
