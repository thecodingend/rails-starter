require "test_helper"

class CurrentWeatherToolTest < ActiveSupport::TestCase
  test "returns current weather from the weather api" do
    expected = {
      source: "Open-Meteo",
      location: { name: "London" },
      current: { temperature: { value: 14.1, unit: "C" } }
    }

    original = OpenMeteoApi.method(:current_weather)
    OpenMeteoApi.define_singleton_method(:current_weather) { |location:| expected }

    begin
      assert_equal expected, CurrentWeatherTool.new.execute(location: "London")
    ensure
      OpenMeteoApi.define_singleton_method(:current_weather) { |location:| original.call(location:) }
    end
  end
end
