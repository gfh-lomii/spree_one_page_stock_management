module Spree
  module Admin
    class StockItemsController < ResourceController
      respond_to :html, :json
      before_action :determine_backorderable, only: :update
      before_action :determine_storage_location, only: :update
      before_action :variant_storage_location, only: :index
      before_action :producer_names, only: :index
      before_action :stock_location
      before_action :set_stock_location_cookie, only: %i[index]
      before_action :set_stock_locations, only: %i[index]

      def index
        respond_to do |format|
          format.js { render layout: false }
          format.html {}
        end
      end

      def update
        stock_item.save
        respond_to do |format|
          format.js { head :ok }
        end
      end

      def create
        stock_movement = stock_location.stock_movements.build(stock_movement_params)
        stock_movement = stock_location.stock_movements.build(stock_movement_params)
        stock_movement.stock_item = stock_location.set_up_stock_item(variant)
        stock_movement.originator = spree_current_user

        if stock_movement.save
          flash[:success] = flash_message_for(stock_movement, :successfully_created)
          respond_to do |format|
            format.json { render json: { stock_item: stock_movement.stock_item, message: flash[:success] } }
            format.html { redirect_back fallback_location: spree.stock_admin_product_url(variant.product) }
          end
        else
          flash[:error] = Spree.t(:could_not_create_stock_movement)
          respond_to do |format|
            format.json {
              render json: {
                errors: stock_movement.errors.full_messages + stock_movement.stock_item.errors.full_messages,
                message: flash[:error]
              }, status: :unprocessable_entity
            }
            format.html { redirect_back fallback_location: spree.stock_admin_product_url(variant.product) }
          end
        end

      end

      def destroy
        stock_item.destroy

        respond_with(stock_item) do |format|
          format.html { redirect_back fallback_location: spree.stock_admin_product_url(stock_item.product) }
          format.js
        end
      end

      private
        def stock_movement_params
          params.require(:stock_movement).permit([:quantity, :stock_item, :stock_item_id, :originator, :action, :reason_id])
        end

        def stock_item
          @stock_item ||= StockItem.find(params[:id])
        end

        def stock_location
          @stock_location_class ||= StockLocation.accessible_by(current_ability, :read)
          @stock_location ||=
            if cookies[:stock_location].present? && !cookies[:stock_location].to_s.eql?('0') &&
              params[:q].blank?
              @stock_location_class.find_by(id: cookies[:stock_location].to_s)
            elsif params[:action] == 'index' && params[:q].blank? ||
              cookies[:stock_location].to_s.eql?('0') && params[:stock_location_id].blank? ||
              params[:q].present? && params[:q][:stock_location_id_eq].blank? ||
              params[:q].present? && params[:q][:stock_location_id_eq].to_s.eql?('0') ||
              nil
            else
              @stock_location_class.find_by(id: params[:stock_location_id]) ||
              @stock_location_class.find_by(id: params[:q][:stock_location_id_eq]) ||
              @stock_location_class.find_by(name: params[:stock_location]) ||
              spree_current_user.stock_locations.first ||
              @stock_location_class.first
            end
        end

        def set_stock_location_cookie
          value =
            if params[:q].present? && params[:q][:stock_location_id_eq].to_s.eql?('0')
              params[:q][:stock_location_id_eq].to_i
            elsif params[:q].blank?
              cookies[:stock_location]
            else
              @stock_location&.id
            end

          cookies[:stock_location] = { :value => value, :expires => 24.hours.from_now }
        end

        def set_stock_locations
          @stock_locations =
            Spree::StockLocation.all.map { |stock_location| [stock_location.name, stock_location.id] }

          @stock_locations << [Spree.t('all'), 0]
        end

        def variant
          @variant ||= Variant.find(params[:variant_id])
        end

        def collection
          #return @collection if @collection.present?
          # params[:q] can be blank upon pagination
          params[:q] = {} if params[:q].blank?

          @collection =
            if stock_location.blank? && params[:q][:stock_location_id_eq].to_s.eql?('0') ||
              stock_location.blank?
              Spree::StockItem.all.
              accessible_by(current_ability, :read).
              includes({ variant: [:product, :images, option_values: :option_type] }).
              order("#{ Spree::Variant.table_name }.product_id")
            else
              stock_location.stock_items.
              accessible_by(current_ability, :read).
              includes({ variant: [:product, :images, option_values: :option_type] }).
              order("#{ Spree::Variant.table_name }.product_id")
            end

           select_all = params[:q][:stock_location_id_eq].to_s.eql?('0')
           params[:q][:stock_location_id_eq] = '' if select_all

          @search = @collection.ransack(params[:q])
          @collection = @search.result.
            page(params[:page]).
            per(params[:per_page] || SpreeOnePageStockManagement::Config[:stock_items_per_page])
          params[:q][:stock_location_id_eq] = '0' if select_all
          @collection
        end

        def variant_storage_location
          @variant_storage_location =
            Spree::Variant.all
                          .map{ |v| [v.storage_location, v.storage_location] }
                          .uniq
                          .delete_if { |k, v| v.blank? }
                          .sort_by{ |k, v| k.downcase }

        end

        def producer_names
          @producer_names =
            Spree::Producer.all
                           .map{ |v| [v.name, v.name] }
                           .uniq
                           .delete_if { |k, v| v.blank? }
                           .sort_by{ |k, v| k.downcase }

        end

        def stock_item_params
          params.require(:stock_item).permit(permitted_stock_item_attributes)
        end

        def determine_backorderable
          stock_item.backorderable =
            params[:stock_item].present? && params[:stock_item][:backorderable].present?
        end

        def determine_storage_location
          return unless params[:stock_item].present? && params[:stock_item][:storage_location].present?
          stock_item.update_columns(storage_location: params[:stock_item][:storage_location])
        end
    end
  end
end
