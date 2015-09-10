class CreateAppThemes < ActiveRecord::Migration
  def change

    create_table :app_themes do |t|

      t.string  :uid, :null => false
      t.string  :name
      t.string  :source_type, :default => 'local'
      t.boolean :repo_private, :default => false
      t.string  :repo_source_url
      t.string  :repo_user

    end

    add_index(:app_themes, :uid, :unique => true)
  end
end