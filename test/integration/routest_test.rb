# encoding: utf-8

require File.expand_path('../../test_helper', __FILE__)

class RoutingTest < ActionDispatch::IntegrationTest

  test "theme_manager" do
    assert_routing({ :path => "/upload-theme", :method => :post }, { :controller => "theme_uploader", :action => "upload" })
    assert_routing({ :path => "/delete-theme/1", :method => :delete }, { :controller => "theme_uploader", :action => "destroy", :id => '1'})
  end
  

end
