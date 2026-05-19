class InventoryItem < ApplicationRecord
  normalizes :name, with: ->(name) { name.to_s.strip.downcase }
end
