class LlmMessage < ApplicationRecord
  acts_as_message chat: :llm_chat, tool_calls: :llm_tool_calls, model: :llm_model
end
