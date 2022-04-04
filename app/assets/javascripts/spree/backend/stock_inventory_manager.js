//= require spree/backend/per_page_selector

function StockInventoryManager(inputs) {
  this.selectBox = inputs.selectBox;
  this.stocksContainer = inputs.stocksContainer;
  this.valid = false;
}

StockInventoryManager.prototype.init = function() {
  this.bindEvents();
};

StockInventoryManager.prototype.bindEvents = function() {
  this.stockLocationChangeEvent();
  this.numberSpinnerEvent();
  this.stockChangeValidateEvent();
  this.stockItemBackorderableEvent();
  this.stockChangeSubmitEvent();
  this.stockItemToDisableEvent();
};

// when stock location is changed
StockInventoryManager.prototype.stockLocationChangeEvent = function() {
  var _this = this;
  this.selectBox.on('change', function() {
    var selectedOption = $(this).find(':selected');
    _this.loadStocks(selectedOption);
  });
};

// when we click +/- option for increasing and decrementing stock
StockInventoryManager.prototype.numberSpinnerEvent = function() {
  var _this = this;
  this.stocksContainer.on('click', '[data-toggle="number_spinner"]', function() {
    var $element = $(this).parents('[data-hook="admin_stock_management_index_rows"]').find('[data-hook="number_spinner"]'),
      action = $(this).data('value'),
      oldValue = $element.data('oldValue'),
      quantity = new Number($element.val());
    if (action === 'increase') {
      $element.val(quantity + 1);
    } else {
      $element.val(quantity - 1);
    }
    _this.valid = _this.validateStockCount($element, oldValue);
  });
};

// when stock count is changed in the text field next to the stock item
StockInventoryManager.prototype.stockChangeValidateEvent = function() {
  var _this = this;
  // Validate after focus lost
  this.stocksContainer.on('blur', '[data-hook="number_spinner"]', function() {
    var $element = $(this);
    _this.valid = _this.validateStockCount($element, $element.data('oldValue'));
  });
};

// when stock item is made backorderable
StockInventoryManager.prototype.stockItemBackorderableEvent = function() {
  var _this = this;
  this.stocksContainer.on('click', '[data-hook="stock_item_backorderable"]', function() {
    _this.valid = true;
  });
};

// when stock item is made to disable
StockInventoryManager.prototype.stockItemToDisableEvent = function() {
  var _this = this;
  this.stocksContainer.on('click', '[data-hook="stock_item_to_disable"]', function() {
    _this.valid = true;
  });
};

// save event of changed stock item
StockInventoryManager.prototype.stockChangeSubmitEvent = function() {
  var _this = this;
  this.stocksContainer.on('click', '[data-hook="stock_item_submit"]', function(event) {
    var reasonId = $(this).closest('[data-hook="form-stock-movement-reason"]').find('[data-hook="stock_movement[reason_id]"]').val();
    if (!reasonId) {
      var alertMovement = $(this).closest('[data-hook="form-stock-movement-reason"]').find('[data-hook="alert-invalid-movement"]');
      alertMovement.show();
      setTimeout(function(){
        alertMovement.hide();
      },3000)
      return;
    }
    event.preventDefault();
    if (_this.valid) {
      var $stockItem = $(this).parents('[data-hook="admin_stock_management_index_rows"]'),
        $element = $stockItem.find('[data-hook="number_spinner"]'),
        $stockQuantityElement = $stockItem.find('input[data-hook="stock_movement_quantity"]');
      $.ajax({
        method: 'POST',
        url: $(this).data('href'),
        data: {
          authenticity_token: AUTH_TOKEN
        },
        beforeSend: function(jqXHR, settings) {
          var quantity = new Number($element.val() - $element.data('oldValue'));
          $stockQuantityElement.val(quantity);
          settings.data += '&' + $stockItem.find('[data-behavior="form"]').serialize(); 
        },
        success: function(response) {
          $element.data('oldValue', response.stock_item.count_on_hand);
          $stockItem.find('[data-hook="current_count_on_hand"]').html(response.stock_item.count_on_hand);
          show_flash('success', response.message);
        },
        error: function(response) {
          show_flash('error', response.responseJSON.errors);
        }
      });
    }
  });
};

StockInventoryManager.prototype.validateStockCount = function($element, oldValue) {
  // Check for insane values
  var value = new Number($element.val());
  if (isNaN(value)) {
    $element.val(oldValue);
    return false;
  } else {
    return true;
  }
};

StockInventoryManager.prototype.loadStocks = function($selectedOption) {
  var url = $selectedOption.data('url');
  window.history.pushState({}, '', url);
  $.ajax({
    method: "GET",
    url: url,
    dataType: 'script',
    cache: true,
    success: function(data) {
      var inputs = {
        perPageElement: $(".js-per-page-select")
      };
      new PerPageSelector(inputs).init();
    }
  });
};

$(function() {
  var inputs = {
    selectBox: $('select[data-hook="stock-location-selector"]'),
    stocksContainer: $('[data-hook="admin_stock_inventory_management"]')
  },
    stockInventoryManager = new StockInventoryManager(inputs);
  stockInventoryManager.init();
});
