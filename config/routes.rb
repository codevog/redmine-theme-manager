post 'upload-theme', :to => 'theme_uploader#upload', :as => 'upload_theme'
delete 'delete-theme/:id', :to => 'theme_uploader#destroy', :as => 'delete_theme'

scope :admin, :path => 'admin' do
  resources :app_themes do
    member do
      get :apply
      match :reload, :via => [:get, :post]
    end
  end
end