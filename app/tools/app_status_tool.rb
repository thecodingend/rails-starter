class AppStatusTool < RubyLLM::Tool
  desc "Returns basic runtime information about this Rails application."

  def name
    "app_status"
  end

  def execute
    {
      environment: Rails.env,
      rails_version: Rails.version,
      ruby_version: RUBY_VERSION,
      current_time: Time.current.iso8601
    }
  end
end
