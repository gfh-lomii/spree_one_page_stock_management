(function() {
    jQuery(function () {
        $('[data-hook="admin_stock_inventory_management"]').on('click', '.stock_item_to_disable', function () {
            return $(this).parent('form').submit();
        });
        return $('[data-hook="admin_stock_inventory_management"]').on('submit', '.toggle_stock_item_to_disable', function () {
            $.ajax({
                type: this.method,
                url: this.action,
                data: $(this).serialize()
            });
            return false;
        });
    });
}).call(this);
