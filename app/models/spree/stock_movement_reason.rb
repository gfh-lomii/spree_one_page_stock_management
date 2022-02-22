module Spree
  class StockMovementReason < Spree::Base
    acts_as_paranoid

    has_many :stock_movements, class_name: 'Spree::StockMovement', foreign_key: :reason_id
    has_many :inventories, class_name: 'Spree::Inventory'

    validates :reason, presence: true

    scope :only_enable, -> { where("enabled = true") }
  end
end
