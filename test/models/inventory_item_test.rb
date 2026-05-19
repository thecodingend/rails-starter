require "test_helper"

class InventoryItemTest < ActiveSupport::TestCase
  test "normalizes names before saving" do
    item = InventoryItem.create!(name: " Sprocket ", quantity: 3)

    assert_equal "sprocket", item.name
  end

  test "inventory api counts items by normalized name" do
    result = InventoryApi.count_items(name: " Widget ")

    assert_equal({ name: "widget", quantity: 42, found: true }, result)
  end

  test "inventory api falls back from plural to singular item names" do
    result = InventoryApi.count_items(name: "widgets")

    assert_equal({ name: "widget", quantity: 42, found: true }, result)
  end
end
