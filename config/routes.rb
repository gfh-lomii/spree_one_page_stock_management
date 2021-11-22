Spree::Core::Engine.add_routes do
  # Add your extension routes here
  namespace :admin, path: Spree.admin_path do
    resources :stock_items do
      collection do
        post :import
      end
    end
    resources :stock_movement_reasons
  end
end
