module Spree
  class StockMovementReason < Spree::Base
    acts_as_paranoid

    has_one :spree_stock_movement_reason

    validates :reason, presence: true

    scope :only_enable, -> { where("enabled = true") }
  end
end
