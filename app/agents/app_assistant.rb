class AppAssistant < RubyLLM::Agent
  chat_model LlmChat
  model ENV.fetch("NVIDIA_MODEL", "mistralai/mistral-medium-3.5-128b"),
    provider: :openai,
    assume_model_exists: true
  instructions "You are a concise assistant for inspecting this Rails app. " \
    "Use the app_status tool when asked about runtime status, versions, environment, or current time. " \
    "Use the inventory_count tool when asked how many units of an item are available. " \
    "Use the current_weather tool when asked about current weather for a location. " \
    "Use the internal_pdf_search tool when asked questions that should be answered from the internal PDF document."
  temperature 0.0
  params do
    params = {
      max_tokens: 128,
      top_p: 0.95,
      tool_choice: "auto"
    }

    params[:chat_template_kwargs] = { enable_thinking: false } if ENV["NVIDIA_ENABLE_THINKING_KWARGS"].present?
    params
  end
  tools AppStatusTool, InventoryCountTool, CurrentWeatherTool, InternalPdfSearchTool
end
