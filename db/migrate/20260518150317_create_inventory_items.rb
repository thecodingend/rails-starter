class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items do |t|
      t.string :name, null: false
      t.integer :quantity, null: false, default: 0

      t.timestamps
    end

    add_index :inventory_items, :name, unique: true
    add_check_constraint :inventory_items, "quantity >= 0", name: "inventory_items_quantity_non_negative"
  end
end
