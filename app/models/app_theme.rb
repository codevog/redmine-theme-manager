class AppTheme  < ActiveRecord::Base
  unloadable

  before_validation :set_name
  validates_url :repo_source_url, :allow_blank => true, :schemes => %w(http https git)
  #validate :check_custom_data
  validates :uid, :presence => true, :uniqueness => true
  validates :repo_source_url, :presence => true, :if => :git_repository?
  validates :repo_user, :presence => true, :if => :git_user_credential_auth?
  validates :deploy_key, :presence => true, :if => :git_deploy_key_auth?


  def git_user_credential_auth?
    git_repository? and self.repo_credential_type == 1
  end

  def git_deploy_key_auth?
    git_repository? and self.repo_credential_type == 2
  end

  def git_repository?
    self.source_type == 'git'
  end


  private
  def set_name
    self.name = self.uid if self.name.blank?
  end
end