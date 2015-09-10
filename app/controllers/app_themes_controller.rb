require 'zip'
require 'uri'

class AppThemesController < ApplicationController
  unloadable
  layout 'admin'

  helper SortHelper
  helper QueriesHelper
  include SortHelper
  include QueriesHelper
  include ActionView::Helpers::NumberHelper

  before_filter :require_admin, :init_plugin
  before_filter :init_current_theme, :only => [:index, :apply, :destroy]

  def index
    if params[:query_id].present?
      @query = AppThemesQuery.find(params[:query_id], :conditions => {})
    else
      @query = (session[:app_themes_query][:id] && AppThemesQuery.find(session[:app_themes_query][:id])) || AppThemesQuery.new(session[:app_themes_query]) if session[:app_themes_query].present?
    end

    @query ||=  AppThemesQuery.new({:name => "_"})
    @query.build_from_params(params)

    if @query.id
      session[:app_themes_query] ||= {:id => @query.id, :filters => @query.filters, :name => @query}
    end

    sort_init(@query.sort_criteria)
    sort_update(@query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    if @query.valid?
      @limit = per_page_option
      @app_themes_count = @query.object_count
      @app_themes_pages = Paginator.new(@app_themes_count, per_page_option, params['page'])
      @app_themes = @query.results_scope(
          :search => params[:search],
          :order => sort_clause,
          :limit  =>  @limit,
          :offset =>  @app_themes_pages.offset,
          :conditions => []
      )
    else
      @app_themes = []
    end
  end

  def new
    @app_theme = AppTheme.new({})
    @post_url  = app_themes_path
  end

  def create
    if params[:app_theme]
      @app_theme = AppTheme.new(get_params_for_theme)

      unless @app_theme.valid?
        @post_url  = app_themes_path
        render 'new'
      else
        ##########################
        ## install theme
        install_theme(@app_theme)
        ###########################
        @app_theme.repo_pwd = ""
        unless @app_theme.git_repository?
          original_filename = params[:app_theme][:theme_archive].original_filename.dup
          @app_theme.archive_filename = original_filename if original_filename.present?
        end
        @app_theme.save!
        flash[:notice] = t('themes.successful_uploaded')
        redirect_to app_themes_path
      end
    end
  rescue Git::GitExecuteError => git_error
    flash[:error] = git_error.message.split("\n").last
    render 'new'
  rescue Zip::Error => zip_error
    flash[:error] = t('theme_manager.incorrect_type')
    render 'new'
  rescue Exception => error
    flash[:error] = error.message
    render 'new'
  ensure
    @app_theme ||= AppTheme.new(get_params_for_theme)
  end

  def edit
    @app_theme = AppTheme.find(params[:id])
    @post_url  = app_theme_path(@app_theme.id)
  end

  def update
    if params[:app_theme]
      @app_theme = AppTheme.find(params[:id])
      params[:app_theme].each do |field, value|
        @app_theme[field.to_sym] = value
      end

      if params[:update_repository].present?
        install_with_git(@app_theme)
        Redmine::Themes.rescan
      end

      @app_theme.repo_pwd = ""
      @app_theme.save!
      flash[:notice] = t('themes.successful_uploaded')
      redirect_to app_themes_path
    end
  rescue Git::GitExecuteError => git_error
    flash[:error] = git_error.message.split("\n").last
    render 'edit'
  rescue Exception => error
    flash[:error] = error.message
    render 'edit'
  end

  def destroy
    @app_theme = AppTheme.find(params[:id])
    if File.exists?(File.join(Rails.public_path, 'themes', @app_theme.uid))
      delete_all(File.join(Rails.public_path, 'themes', @app_theme.uid))
    end
    @app_theme.destroy
    Redmine::Themes.rescan
    if !@current_theme_instance.new_record? and @current_theme_instance.value == @app_theme.uid
      @current_theme_instance.value = nil
      @current_theme_instance.save!
    end

    flash[:notice] = t('themes.successful_deleted')
  rescue Exception => error
    flash[:error] = error.message
  ensure
    redirect_to app_themes_path
  end

  def apply
    @app_theme = AppTheme.find(params[:id])
    @current_theme_instance.value = @app_theme.uid
    @current_theme_instance.save!
    flash[:notice] = t('themes.successful_apply')
  rescue Exception => error
    flash[:error] = error.message
  ensure
    redirect_to app_themes_path
  end

  def reload
    @app_theme = AppTheme.find(params[:id])
    if @app_theme.git_repository?
      render 'reload_auth_repository' and return false if @app_theme.git_user_credential_auth? and params[:password].blank?
      @app_theme.repo_pwd = params[:password] if @app_theme.git_user_credential_auth?
      install_with_git(@app_theme)
      Redmine::Themes.rescan
      @app_theme.repo_pwd = ""
    else
      raise t('themes.wrong_source_type')
    end
    flash[:notice] = t('themes.successful_reload')
    redirect_to app_themes_path
  rescue ActiveRecord::RecordNotFound => ex
    render_404
  rescue Exception => ex
    flash[:error] = ex.message
    redirect_to app_themes_path
  end

  private
  def init_plugin
    @plugin = Redmine::Plugin.find(:theme_manager)
  end

  def get_params_for_theme
    if params[:app_theme]
      _data = params[:app_theme].dup
      _data.delete(:theme_archive)
    end
    _data || {}
  end

  def install_with_archive(archive_path, theme_id)
    _extract_dir = File.join(Rails.root.to_s, 'tmp', 'theme_extract', Time.now.to_i.to_s)
    if File.exists?(_extract_dir)
      delete_all(_extract_dir)
    end
    #FileUtils.mkdir_p(_extract_dir, :verbose => true)
    Dir.mkdir(_extract_dir)
    Zip.sort_entries = true
    Zip::File.open(archive_path) do |zip_file|
      zip_file.each do |entry|
        entry.extract(File.join(_extract_dir, entry.name))
      end
      zip_file.first.try(:name).to_s.gsub('/', '')
    end

    ### chech theme directory
    _source_path = theme_path(_extract_dir)
    raise t('theme_manager.theme_not_valid') unless File.exists?(_source_path)

    _dist_path = File.join(Rails.public_path, 'themes', theme_id)
    copy_theme(_source_path, _dist_path)
  end

  def install_with_git(app_theme)
    _extract_dir = File.join(Rails.root.to_s, 'tmp', 'theme_extract', Time.now.to_i.to_s)
    if File.exists?(_extract_dir)
      delete_all(_extract_dir)
    end
    #FileUtils.mkdir_p(_extract_dir, :verbose => true)
    Dir.mkdir(_extract_dir)
    uri = URI.parse(app_theme.repo_source_url)

    case app_theme.repo_credential_type
      when 0
        uri.user     ||= 'git'
        uri.password = 'empty-password'
      when 1
        raise t('theme_manager.provide_repository_credentials') unless app_theme.repo_user.present?
        uri.user = app_theme.repo_user
        uri.password = app_theme.repo_pwd.blank? ? 'empty-password' : app_theme.repo_pwd
    end

    Git.export(uri.to_s, _extract_dir)

    ### chech theme directory
    _source_path = theme_path(_extract_dir)
    raise t('theme_manager.theme_not_valid') unless File.exists?(_source_path)

    _dist_path = File.join(Rails.public_path, 'themes', app_theme.uid)
    delete_all(_dist_path) if File.exists?(_dist_path)
    copy_theme(_source_path, _dist_path)
  end

  def copy_theme(source_dir, dist_dir, delete_source=true)
    Dir.mkdir(dist_dir) unless  File.exists?(dist_dir)
    Dir[File.join(source_dir, '**', '*')].each do |_rec_path|
      _new_dist_path = _rec_path.gsub(source_dir, dist_dir)
      if FileTest::directory?(_rec_path)
        #FileUtils.mkdir_p(_new_dist_path, :verbose => true) unless File.exists?(_new_dist_path)
        Dir.mkdir(_new_dist_path) unless File.exists?(_new_dist_path)
      else
        File.delete(_new_dist_path) if File.exists?(_new_dist_path)
        FileUtils.cp(_rec_path, _new_dist_path)
      end
    end
    delete_all(source_dir) if delete_source
  end

  def get_archive_path
    request_file = params[:app_theme] && params[:app_theme][:theme_archive]
    raise t('theme_manager.file_not_found') unless request_file.present?
    raise t('theme_manager.incorrect_size', :size => number_to_human_size(ThemeManagerSettings::MAX_FILE_SIZE)) if request_file.try(:size) > ThemeManagerSettings::MAX_FILE_SIZE

    archives_dir = File.join(Rails.root, 'tmp', 'theme_archives')
    #FileUtils.mkdir_p(archives_dir, :verbose => true) unless File.exists?(archives_dir)
    Dir.mkdir(archives_dir) unless File.exists?(archives_dir)
    tmp_file_path = File.join(archives_dir, request_file.original_filename)

    File.open(tmp_file_path, "wb") do |output|
      while buff = request_file.read(4096)
        output.write(buff)
      end
    end
    tmp_file_path
  end

  def install_theme(app_theme)
    _extract_dir = File.join(Rails.root.to_s, 'tmp', 'theme_extract')
    Dir.mkdir(_extract_dir) unless File.exists?(_extract_dir)
    case app_theme.source_type
      when 'local'
        _archive_path = get_archive_path()
        install_with_archive(_archive_path, app_theme.uid)
      when 'git'
        install_with_git(app_theme)
    end
    Redmine::Themes.rescan
  end

  def delete_all(dir)
    Dir.foreach(dir) do |e|
      next if [".",".."].include? e
      fullname = dir + File::Separator + e
      if FileTest::directory?(fullname)
        delete_all(fullname)
      else
        File.delete(fullname)
      end
    end
    Dir.delete(dir)
  end

  def theme_path(dir)
    _theme_folders = %w(stylesheets)
    _theme_path = ''
    Dir[File.join(dir, '**', '*')].each do |path|
      if FileTest::directory?(path)
        _path_items = path.split('/')
        if _theme_folders.include?(_path_items.last.try{|it| it.downcase}) and File.exists?(File.join(path, 'application.css'))
          _theme_path = _path_items[0..-2].join('/')
          break
        end
      end
    end
    _theme_path
  end

  def init_current_theme
    @current_theme_instance = Setting.find_by_name(:ui_theme) || Setting.new({:name => 'ui_theme'})
    @current_theme_instance.save! if @current_theme_instance.new_record?
  end
end