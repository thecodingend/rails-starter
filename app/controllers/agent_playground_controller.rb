require "timeout"

class AgentPlaygroundController < InertiaController
  AGENT_TIMEOUT_SECONDS = 1000

  def index
    render inertia: {
      configured: llm_api_key_configured?,
      chats: recent_chats.map { |chat| serialize_chat(chat) }
    }
  end

  def create
    chat = nil
    prompt = params[:prompt].to_s.strip

    if prompt.blank?
      redirect_to agent_playground_path, alert: "Prompt can't be blank"
      return
    end

    unless llm_api_key_configured?
      redirect_to agent_playground_path, alert: "Set NVIDIA_API_KEY or OPENAI_API_KEY before asking the agent."
      return
    end

    chat = AppAssistant.create!
    Timeout.timeout(AGENT_TIMEOUT_SECONDS) { chat.ask(prompt) }

    redirect_to agent_playground_path, notice: "Agent run completed."
  rescue RubyLLM::Error => error
    chat&.destroy
    redirect_to agent_playground_path, alert: error.message
  rescue Timeout::Error
    chat&.destroy
    redirect_to agent_playground_path, alert: "The agent took longer than #{AGENT_TIMEOUT_SECONDS} seconds. Try again or switch to a faster model."
  end

  private

  def recent_chats
    LlmChat.includes(llm_messages: :llm_tool_calls).order(created_at: :desc).limit(10)
  end

  def serialize_chat(chat)
    {
      id: chat.id,
      created_at: chat.created_at.iso8601,
      messages: chat.llm_messages.sort_by(&:created_at).map { |message| serialize_message(message) }
    }
  end

  def serialize_message(message)
    {
      id: message.id,
      role: message.role,
      content: message.content,
      tool_calls: message.llm_tool_calls.map { |tool_call| serialize_tool_call(tool_call) }
    }
  end

  def serialize_tool_call(tool_call)
    {
      id: tool_call.id,
      name: tool_call.name,
      arguments: tool_call.arguments
    }
  end

  def llm_api_key_configured?
    ENV["NVIDIA_API_KEY"].present? ||
      ENV["llm_api_key"].present? ||
      Rails.application.credentials.dig(:llm_api_key).present?
  end
end
