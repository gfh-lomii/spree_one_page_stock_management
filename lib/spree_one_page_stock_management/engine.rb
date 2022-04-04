module SpreeOnePageStockManagement
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_one_page_stock_management'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      unless Spree::PermittedAttributes.stock_item_attributes.include?(:storage_location)
        Spree::PermittedAttributes.stock_item_attributes << :storage_location
      end

      unless Spree::PermittedAttributes.stock_item_attributes.include?(:to_disable)
        Spree::PermittedAttributes.stock_item_attributes << :to_disable
      end

      Spree::StockItem.class_eval do
        # def self.search_variant_product_name(query)
        #   if defined?(SpreeGlobalize)
        #     joins(variant: { product: :translations }).where("#{Spree::Product::Translation.table_name}.name LIKE :query", query: "%#{query}%")
        #   else
        #     variant_product_name_cont(query)
        #   end
        # end
      end
    end

    initializer "spree_one_page_stock_management.preferences", before: :load_config_initializers do
      SpreeOnePageStockManagement::Config = Spree::SpreeOnePageStockManagementSetting.new
    end

    unless Spree::PermittedAttributes.stock_movement_attributes.include?(:reason_id)
      Spree::PermittedAttributes.stock_movement_attributes << :reason_id
    end

    unless Spree::PermittedAttributes.stock_movement_attributes.include?(:order_id)
      Spree::PermittedAttributes.stock_movement_attributes << :order_id
    end

    unless Spree::PermittedAttributes.stock_movement_attributes.include?(:order_number)
      Spree::PermittedAttributes.stock_movement_attributes << :order_number
    end

    config.to_prepare &method(:activate).to_proc
  end
end
