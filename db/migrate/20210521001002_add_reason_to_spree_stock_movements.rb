class AddReasonToSpreeStockMovements < ActiveRecord::Migration[6.0]
  def change
    add_reference :spree_stock_movements, :reason
  end
end
