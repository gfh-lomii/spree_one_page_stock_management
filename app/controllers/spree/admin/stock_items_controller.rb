module Spree
  module Admin
    class StockItemsController < ResourceController
      respond_to :html, :json
      before_action :determine_backorderable, only: :update
      before_action :determine_disable, only: :update
      before_action :determine_storage_location, only: :update
      before_action :determine_security_stock, only: :update
      before_action :variant_storage_location, only: :index
      before_action :producer_names, only: :index
      before_action :stock_location
      before_action :set_stock_location_cookie, only: %i[index]
      before_action :set_stock_locations, only: %i[index]

      def index
        respond_to do |format|
          format.js { render layout: false }
          format.html {}
          format.csv { send_data stock_items_csv, encoding: 'UTF-8', filename: "stock-items-#{Date.today}.csv" }
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

      def import
        reason_id = params[:reason_id]
        csv = open(params[:document]).read
        data = CSV.parse(csv, { headers: true })
        data.each do |row|
          begin
            variant_id = row[0]
            sku = row[3]
            #Example:
            #CD - CENTRO DE DISTRIBUCION
            #LF - La Florida
            #LC - Las Condes
            #NN - Ñuñoa
            #VM - Viña del Mar
            variant = current_store.variants.find_by_id(variant_id)
            variant ||= current_store.variants.find_by_sku(sku)
            if variant
              codes = set_codes
              codes.each do |internal_code|
                stock_item = variant.stock_items.find{ |si| si.stock_location.internal_code == internal_code }
                row_num = 5+codes.index(internal_code)
                stock =row[row_num]
                next if stock.to_i.eql?(0)

                unless stock_item
                  _stock_location = current_store.stock_locations.find_by(internal_code: internal_code)
                  next unless _stock_location
                  _stock_item = variant.stock_items.build(stock_location: _stock_location)
                  _stock_item.save
                  stock_item = _stock_item
                end
                stock_movement = stock_item.stock_location.stock_movements.build(quantity: stock.to_i, reason_id: reason_id)
                stock_movement.stock_item = stock_item.stock_location.set_up_stock_item(variant)
                stock_movement.originator = spree_current_user
                stock_movement.save
              end
            end
          rescue => e
            puts ">>>>> error: #{e}"
            next
          end
        end
        redirect_to request.referrer, flash: { success: t('.success') }
      end

      def set_codes
        current_store&.stock_locations&.map(&:internal_code)&.reject(&:blank?) ||
        spree_current_user&.stock_locations.map(&:internal_code)&.reject(&:blank?) ||
        Spree::StockLocation.all.map(&:internal_code).reject(&:blank?)
      end

      private
        def stock_movement_params
          params.require(:stock_movement).permit(permitted_stock_movement_attributes)
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
            elsif params[:q].present? && params[:q][:stock_location_id_eq].present?
              @stock_location_class.find_by(id: params[:q][:stock_location_id_eq])
            else
              @stock_location_class.find_by(id: params[:stock_location_id]) ||
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
            current_store.stock_locations.all.map { |stock_location| [stock_location.name, stock_location.id] }

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
              current_store.stock_items.
              accessible_by(current_ability, :read).
              includes({ variant: [:product, :images, option_values: :option_type] }).
              where(spree_variants: { is_master: false, discontinue_on: nil }).
              order("#{ Spree::Variant.table_name }.product_id")
            else
              stock_location.stock_items.
              accessible_by(current_ability, :read).
              includes({ variant: [:product, :images, option_values: :option_type] }).
              where(spree_variants: { is_master: false, discontinue_on: nil }).
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
            current_store.variants
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

        def determine_disable
          stock_item.to_disable =
            params[:stock_item].present? && params[:stock_item][:to_disable].present?
        end

        def determine_storage_location
          return unless params[:stock_item].present? && params[:stock_item][:storage_location].present?
          stock_item.update_columns(storage_location: params[:stock_item][:storage_location])
        end

        def determine_security_stock
          return unless params[:stock_item].present? && params[:stock_item][:security_stock].present?
          stock_item.update_columns(security_stock: params[:stock_item][:security_stock])
        end

        def stock_items_csv
          codes = set_codes
          zeros = []
          codes.each{ |c| zeros.push(0) }

          column_attributes = %w{ID NAME PORDUCER SKU OPTIONS} + codes
          _collection = current_store.variants.
                        includes(:product, stock_items: :stock_location, option_values: :option_type).
                        where(id: @search.result.pluck(:variant_id).uniq)

          CSV.generate(headers: true) do |csv|
            csv << column_attributes
            _collection.each do |variant|
              row = [
                variant.id,
                variant.product.name,
                variant.producer&.name || variant.product.producer&.name,
                variant.sku,
                variant.options_text
              ] + zeros
              csv << row
            end
          end
        end
    end
  end
end
