class LlmToolCall < ApplicationRecord
  acts_as_tool_call message: :llm_message
end
