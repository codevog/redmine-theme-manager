class AddCredentialFieldsToAppThemes < ActiveRecord::Migration
  def change
    add_column :app_themes, :deploy_key, :text,    :default => nil, :null => true
    add_column :app_themes, :repo_credential_type, :integer, :default => 0, :null => true # 0 - public repository 1 - user credential 2 - deploy key
    add_column :app_themes, :repo_pwd, :string,    :default => nil, :null => true
  end
end