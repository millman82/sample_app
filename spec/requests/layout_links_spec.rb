require 'spec_helper'

describe "LayoutLinks" do

  it "should have a Home page at '/'" do
    get '/'
    response.body.should have_selector('title', :text => "Home")
  end
  
  it "should have a Contact page at '/contact'" do
    get '/contact'
    response.body.should have_selector('title', :text => "Contact")
  end
  
  it "should have an About page at '/about'" do
    get '/about'
    response.body.should have_selector('title', :text => "About")
  end
  
  it "should have a Help page at '/help'" do
    get '/help'
    response.body.should have_selector('title', :text => "Help")
  end
  
end
