RubyLLM.configure do |config|
  if ENV["NVIDIA_API_KEY"].present?
    config.openai_api_key = ENV["NVIDIA_API_KEY"]
    config.openai_api_base = ENV.fetch("NVIDIA_API_BASE", "https://integrate.api.nvidia.com/v1")
    config.openai_use_system_role = true
  else
    config.openai_api_key = ENV["OPENAI_API_KEY"].presence ||
      ENV["llm_api_key"].presence ||
      Rails.application.credentials.dig(:llm_api_key)
  end

  # config.default_model = "gpt-5-nano"

  # Custom model registry class name
  config.model_registry_class = "LlmModel"
end
