Deface::Override.new(
  virtual_path: 'spree/admin/shared/sub_menu/_configuration',
  name: 'add_stock_movement_reason_link_configuration_menu',
  insert_bottom: '[data-hook="admin_configurations_sidebar_menu"]',
  text: '<%= configurations_sidebar_menu_item plural_resource_name(Spree::StockMovementReason), spree.admin_stock_movement_reasons_path %>'
)