require File.expand_path('../../test_helper', __FILE__)
require 'fileutils'

class AppThemesControllerTest < ActionController::TestCase

  def setup
    @controller = AppThemesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    User.current = nil
    @request.session[:user_id] = 1
  end

  def test_upload_and_destroy
    theme_name = 'test'
    theme_dir = File.join(Rails.public_path, 'themes')

    theme_data = {:name => theme_name, :uid => theme_name, :source_type => 'local', :theme_archive => nil}
    post :create, :app_theme => theme_data
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:app_theme)
    assert_equal I18n.t('theme_manager.file_not_found'), flash[:error]

    theme_data[:theme_archive] = uploaded_theme_file('test.zip', 'application/zip')
    post :create, :app_theme => theme_data
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_not_nil assigns(:app_theme)
    _new_theme = assigns(:app_theme)
    assert_equal I18n.t('themes.successful_uploaded'), flash[:notice]
    theme_path = File.join(theme_dir, theme_name)
    assert File.exist?(theme_path)

    theme = Redmine::Themes.theme(theme_name)
    assert_not_nil theme

    post :reload, :id => _new_theme.id
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_equal I18n.t('themes.wrong_source_type'), flash[:error]

    post :create, :app_theme => theme_data
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:app_theme)
    assert assigns(:app_theme).errors.size > 0

    delete :destroy, :id => 0
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_not_nil flash[:error]

    delete :destroy, :id => _new_theme.id
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_equal I18n.t('themes.successful_deleted'), flash[:notice]
    assert !File.exist?(theme_path)
    assert_nil Redmine::Themes.theme(theme_name)
  end

  def test_upload_from_git
    theme_name = 'test_theme'
    theme_dir = File.join(Rails.public_path, 'themes')

    theme_data = {:name => theme_name, :uid => theme_name, :source_type => 'git', :repo_source_url => nil, :repo_credential_type => 0}
    post :create, :app_theme => theme_data
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:app_theme)
    assert_nil flash[:error]
    assert assigns(:app_theme).errors.size > 0

    theme_data[:repo_source_url] = '/test'
    post :create, :app_theme => theme_data
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:app_theme)
    assert_nil flash[:error]
    assert assigns(:app_theme).errors.size > 0

    theme_data[:repo_source_url] = 'https://bitbucket.org/theme_manager/invalid'
    post :create, :app_theme => theme_data
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:app_theme)
    assert_not_nil flash[:error]
    theme_path = File.join(theme_dir, theme_name)
    assert !File.exist?(theme_path)

    theme_data[:repo_source_url] = 'https://bitbucket.org/theme_manager/test_theme'
    post :create, :app_theme => theme_data
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_not_nil assigns(:app_theme)
    _new_theme = assigns(:app_theme)
    assert_equal I18n.t('themes.successful_uploaded'), flash[:notice]
    theme_path = File.join(theme_dir, theme_name)
    assert File.exist?(theme_path)

    theme = Redmine::Themes.theme(theme_name)
    assert_not_nil theme

    _test_file = File.join(theme_dir, theme_name, '_test_file')
    File.open(_test_file, 'wb') do |f|
      f.write('qwe')
    end
    assert File.exist?(_test_file)

    post :reload, :id => 0
    assert_response 404

    post :reload, :id => _new_theme.id
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_equal I18n.t('themes.successful_reload'), flash[:notice]
    theme_path = File.join(theme_dir, theme_name)
    assert File.exist?(theme_path)
    assert !File.exist?(_test_file)

    delete :destroy, :id => _new_theme.id
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_equal I18n.t('themes.successful_deleted'), flash[:notice]
    assert !File.exist?(theme_path)
    assert_nil Redmine::Themes.theme(theme_name)

    # require auth
    theme_data[:repo_source_url] = 'https://bitbucket.org/adabash/test_theme'
    theme_data[:repo_credential_type] = 1
    post :create, :app_theme => theme_data
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:app_theme)
    assert_nil flash[:error]
    assert assigns(:app_theme).errors.size > 0
    theme_path = File.join(theme_dir, theme_name)
    assert !File.exist?(theme_path)

    theme_data[:repo_user] = 'theme_manager'
    post :create, :app_theme => theme_data
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:app_theme)
    assert_not_nil flash[:error]
    theme_path = File.join(theme_dir, theme_name)
    assert !File.exist?(theme_path)

    theme_data[:repo_pwd] = 'qwerty12'
    post :create, :app_theme => theme_data
    assert_response :success
    assert_template :new
    assert_not_nil assigns(:app_theme)
    assert_not_nil flash[:error]
    theme_path = File.join(theme_dir, theme_name)
    assert !File.exist?(theme_path)

    theme_data[:repo_pwd] = 'pa33word'
    post :create, :app_theme => theme_data
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_not_nil assigns(:app_theme)
    assert_equal '', assigns(:app_theme).repo_pwd
    _new_theme = assigns(:app_theme)
    assert_equal I18n.t('themes.successful_uploaded'), flash[:notice]
    theme_path = File.join(theme_dir, theme_name)
    assert File.exist?(theme_path)

    theme = Redmine::Themes.theme(theme_name)
    assert_not_nil theme

    _test_file = File.join(theme_dir, theme_name, '_test_file')
    File.open(_test_file, 'wb') do |f|
      f.write('qwe')
    end
    assert File.exist?(_test_file)

    post :reload, :id => 0
    assert_response 404

    post :reload, :id => _new_theme.id
    assert_response :success
    assert_template :reload_auth_repository
    assert File.exist?(_test_file)

    post :reload, :id => _new_theme.id, :password => 'pa33word'
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_equal I18n.t('themes.successful_reload'), flash[:notice]
    assert_equal '', assigns(:app_theme).repo_pwd
    theme_path = File.join(theme_dir, theme_name)
    assert File.exist?(theme_path)
    assert !File.exist?(_test_file)

    delete :destroy, :id => _new_theme.id
    assert_redirected_to :controller => 'app_themes', :action => 'index'
    assert_equal I18n.t('themes.successful_deleted'), flash[:notice]
    assert !File.exist?(theme_path)
    assert_nil Redmine::Themes.theme(theme_name)
  end
end
