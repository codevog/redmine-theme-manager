class ThemeManagerSettings
  MAX_FILE_SIZE = 10485760
end

module RedmineApp
  class Application < Rails::Application
    config.filter_parameters += [:repo_pwd]
  end
end