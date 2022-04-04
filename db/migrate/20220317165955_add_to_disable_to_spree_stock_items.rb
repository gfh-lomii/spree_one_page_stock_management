class AddToDisableToSpreeStockItems < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_stock_items, :to_disable, :boolean, default: false
  end
end
