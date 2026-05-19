require "test_helper"

class AgentPlaygroundControllerTest < ActionDispatch::IntegrationTest
  test "renders the agent playground" do
    get agent_playground_path

    assert_inertia_response
    assert_inertia_component "agent_playground/index"
    assert_inertia_props chats: []
  end

  test "rejects a blank prompt" do
    post agent_playground_path, params: { prompt: "" }

    assert_redirected_to agent_playground_path
    follow_redirect!
    assert_inertia_flash alert: "Prompt can't be blank"
  end

  test "redirects when the agent times out" do
    previous_key = ENV["NVIDIA_API_KEY"]
    original_create = AppAssistant.method(:create!)
    ENV["NVIDIA_API_KEY"] = "test"
    chat = TimeoutChat.new

    AppAssistant.define_singleton_method(:create!) { chat }
    post agent_playground_path, params: { prompt: "How many widgets do we have?" }

    assert chat.destroyed?
    assert_redirected_to agent_playground_path
    follow_redirect!
    assert_inertia_flash alert: "The agent took longer than #{AgentPlaygroundController::AGENT_TIMEOUT_SECONDS} seconds. Try again or switch to a faster model."
  ensure
    ENV["NVIDIA_API_KEY"] = previous_key
    AppAssistant.define_singleton_method(:create!, original_create)
  end

  class TimeoutChat
    def ask(_prompt)
      raise Timeout::Error
    end

    def destroy
      @destroyed = true
    end

    def destroyed?
      @destroyed
    end
  end
end
