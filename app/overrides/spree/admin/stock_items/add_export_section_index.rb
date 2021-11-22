Deface::Override.new virtual_path:  'spree/admin/stock_items/index',
                     name:          'admin_stock_items_export_section',
                     insert_before: '[data-hook="admin_stock_inventory_management"]',
                     partial:       'spree/admin/stock_items/export_section'
