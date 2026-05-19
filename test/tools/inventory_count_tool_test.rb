require "test_helper"

class InventoryCountToolTest < ActiveSupport::TestCase
  test "returns inventory data from the internal api" do
    result = InventoryCountTool.new.execute(name: "Gadgets")

    assert_equal({ name: "gadget", quantity: 17, found: true }, result)
  end
end
