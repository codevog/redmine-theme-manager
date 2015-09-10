# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

class ActiveSupport::TestCase

  def teardown
    FileUtils.rm_rf(File.join(Rails.public_path, 'themes', 'test'), :secure => true)
    FileUtils.rm_rf(File.join(Rails.public_path, 'themes', 'test_theme'), :secure => true)
    FileUtils.rm_rf(File.join(Rails.public_path, 'themes', 'invalid'), :secure => true)
  end
end

def theme_manager_fixture_files_path
  "#{File.dirname(__FILE__)}/fixtures/files/"
end

def uploaded_theme_file(name, mime)
  Rack::Test::UploadedFile.new("#{theme_manager_fixture_files_path}/#{name}", mime)
end