module Spree
  module Admin
    module StockItemsHelper
      def search_params
        params[:q].permit(:variant_product_name_cont, :variant_sku_cont).to_h
      end

      def current_page_params
        # Modify this list to whitelist url params for linking to the current page
        request.params.slice("q", "per_page")
      end
    end
  end
end
