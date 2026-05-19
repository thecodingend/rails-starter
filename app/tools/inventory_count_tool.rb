class InventoryCountTool < RubyLLM::Tool
  desc "Looks up the current inventory quantity for an item by name."
  param :name, type: :string, desc: "The item name to look up, for example widget."

  def execute(name:)
    InventoryApi.count_items(name:)
  end
end
