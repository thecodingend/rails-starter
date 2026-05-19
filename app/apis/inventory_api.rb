class InventoryApi
  def self.count_items(name:)
    requested_name = normalize_name(name)
    return { error: "name is required" } if requested_name.blank?

    item = InventoryItem.find_by(name: requested_name) ||
      InventoryItem.find_by(name: requested_name.singularize)

    {
      name: item&.name || requested_name.singularize,
      quantity: item&.quantity.to_i,
      found: item.present?
    }
  end

  def self.normalize_name(name)
    name.to_s.strip.downcase
  end
end
