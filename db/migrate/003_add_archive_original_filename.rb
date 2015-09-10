class AddArchiveOriginalFilename < ActiveRecord::Migration
  def change
    add_column :app_themes, :archive_filename, :string,  :default => nil, :null => true
  end
end