class LlmModel < ApplicationRecord
  acts_as_model chats: :llm_chats
end
