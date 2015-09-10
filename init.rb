Redmine::Plugin.register :theme_manager do
  name 'Theme Manager plugin'
  author 'Codevog'
  description 'Plugin for managing Redmine themes'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://codevog.com/about'

  menu :admin_menu, :theme_manager, { :controller => 'app_themes', :action => 'index'  }, :caption => 'Theme manager', :html => {:class => 'icon icon-file text-css'}
  settings :default => {
      :empty => true
  }, :partial => 'settings/app_themes_settings'
end

require 'theme_manager'

if (_current_plugin = ::Redmine::Plugin.find(:theme_manager))
  ActiveSupport::Dependencies.autoload_paths += [File.join(_current_plugin.directory, 'app', 'queries')]
end
