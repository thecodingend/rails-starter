class LlmChat < ApplicationRecord
  # rubyllm's acts_as_chat must be included after the model declaration, Its purpose is to set up the necessary associations and methods for the chat functionality.
  # messages: :llm_messages specifies that the chat messages are stored in the llm_messages association,
  # model: :llm_model indicates that the chat uses the llm_model for its language model interactions.
  acts_as_chat messages: :llm_messages, model: :llm_model
end
