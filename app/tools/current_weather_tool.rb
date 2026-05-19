class CurrentWeatherTool < RubyLLM::Tool
  desc "Looks up current weather for a location using Open-Meteo."
  param :location, type: :string, desc: "The city, address, or place to look up, for example London."

  def execute(location:)
    OpenMeteoApi.current_weather(location:)
  end
end
