module Spree
  module StockLocationDecorator
    # Return either an existing stock item or create a new one. Useful in
    # scenarios where the user might not know whether there is already a stock
    # item for a given variant
    def set_up_stock_item(variant)
      si = stock_item(variant)
      return si if si.present?

      stock_items.create!(variant: variant, backorderable: backorderable_default)
    end
  end
end

::Spree::StockLocation.prepend Spree::StockLocationDecorator
