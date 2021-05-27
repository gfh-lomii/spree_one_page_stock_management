module Spree
  module StockMovementDecorator
    def self.prepended(base)
      base.belongs_to :spree_stock_movement_reason, optional: true
    end
  end
end

::Spree::StockMovement.prepend Spree::StockMovementDecorator
