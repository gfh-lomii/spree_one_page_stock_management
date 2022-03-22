module Spree
  module StockItemDecorator
    def self.prepended(base)
      base.after_update_commit :disable_variant_in_stock_location
    end

    def disable_variant_in_stock_location
      return unless variant.product.stock_items.sum(:count_on_hand).zero?
      return unless variant.stock_items.find_by(stock_location_id: stock_location.id).to_disable?
      variant.stock_items.find_by(stock_location_id: stock_location.id).destroy
    end
  end
end

::Spree::StockItem.prepend Spree::StockItemDecorator
