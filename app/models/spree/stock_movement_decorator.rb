module Spree
  module StockMovementDecorator
    def self.prepended(base)
      base.belongs_to :reason, class_name: 'Spree::StockMovementReason'
      base.belongs_to :order, class_name: 'Spree::Order'
      base.after_create :load_history_order
      base.before_create :load_order
    end

    def load_order
      return true if self.order_number.blank?
      self.order_id = Spree::Order.find_by(number: self.order_number).id
    end

    def load_history_order
      return true if self.order_id.blank?

      create_history
    end

    def load_reason_type_id
      reason_type = Spree::ReasonType.name_nocase(self.reason.reason)
      return reason_type.last.id if reason_type.present?

      reason_type = Spree::ReasonType.create(name: self.reason.reason, enabled: true)
      reason_type.id
    end

    def create_history
      reason_type_id = load_reason_type_id
      body = "#{self.reason.reason}. #{self.quantity.to_s} #{self.stock_item.variant_name} (#{self.stock_item.variant.producer.name})"

      self.order.new_history(body, reason_type_id, self.originator_id)
    end
  end
end

::Spree::StockMovement.prepend Spree::StockMovementDecorator
