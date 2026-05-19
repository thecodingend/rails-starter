require "test_helper"

module Internal
  class InventoryItemsControllerTest < ActionDispatch::IntegrationTest
    test "returns inventory count for an item" do
      get internal_inventory_items_count_path, params: { name: "Widgets" }

      assert_response :success
      assert_equal(
        { "name" => "widget", "quantity" => 42, "found" => true },
        JSON.parse(response.body)
      )
    end

    test "rejects blank names" do
      get internal_inventory_items_count_path, params: { name: "" }

      assert_response :bad_request
      assert_equal({ "error" => "name is required" }, JSON.parse(response.body))
    end
  end
end
