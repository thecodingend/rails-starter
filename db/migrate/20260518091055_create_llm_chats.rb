class CreateLlmChats < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_chats do |t|
      t.timestamps
    end
  end
end
