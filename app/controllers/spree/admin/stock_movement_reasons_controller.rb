module Spree
  module Admin
    class StockMovementReasonsController < ResourceController
      def new
      end

      def index
        page = if params[:page].respond_to?(:to_i)
                 params[:page].to_i <= 0 ? 1 : params[:page].to_i
               else
                 1
               end
        curr_page = page || 1
        per_page = 10
        @stock_movement_reasons = Spree::StockMovementReason.all.page(curr_page).per(per_page)
      end
    end
  end
end