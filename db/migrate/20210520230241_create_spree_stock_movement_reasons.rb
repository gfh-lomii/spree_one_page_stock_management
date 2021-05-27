class CreateSpreeStockMovementReasons < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_stock_movement_reasons do |t|
      t.string :reason
      t.boolean :enabled
      t.datetime :deleted_at
      t.index :deleted_at

      t.timestamps
    end
  end
end
