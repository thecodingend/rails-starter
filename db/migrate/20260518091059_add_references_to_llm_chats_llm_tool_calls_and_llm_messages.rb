class AddReferencesToLlmChatsLlmToolCallsAndLlmMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :llm_chats, :llm_model, foreign_key: true
    add_reference :llm_tool_calls, :llm_message, null: false, foreign_key: true
    add_reference :llm_messages, :llm_chat, null: false, foreign_key: true
    add_reference :llm_messages, :llm_model, foreign_key: true
    add_reference :llm_messages, :llm_tool_call, foreign_key: true
  end
end
