require "test_helper"

class OpenMeteoApiTest < ActiveSupport::TestCase
  test "returns current weather data from open meteo" do
    responses = {
      OpenMeteoApi::GEOCODING_URL => {
        "results" => [
          {
            "name" => "London",
            "country" => "United Kingdom",
            "admin1" => "England",
            "latitude" => 51.50853,
            "longitude" => -0.12574,
            "timezone" => "Europe/London"
          }
        ]
      },
      OpenMeteoApi::FORECAST_URL => {
        "timezone" => "Europe/London",
        "current_units" => {
          "temperature_2m" => "C",
          "apparent_temperature" => "C",
          "relative_humidity_2m" => "%",
          "precipitation" => "mm",
          "wind_speed_10m" => "km/h"
        },
        "current" => {
          "time" => "2026-05-19T10:00",
          "temperature_2m" => 14.1,
          "apparent_temperature" => 12.8,
          "relative_humidity_2m" => 72,
          "precipitation" => 0,
          "weather_code" => 2,
          "wind_speed_10m" => 13.4
        }
      }
    }

    with_stubbed_request_json(->(url, _params) { responses.fetch(url) }) do
      result = OpenMeteoApi.current_weather(location: "London")

      assert_equal "Open-Meteo", result[:source]
      assert_equal "London", result.dig(:location, :name)
      assert_equal "United Kingdom", result.dig(:location, :country)
      assert_equal 14.1, result.dig(:current, :temperature, :value)
      assert_equal "C", result.dig(:current, :temperature, :unit)
      assert_equal "partly cloudy", result.dig(:current, :weather, :description)
    end
  end

  test "returns an error when the location is blank" do
    assert_equal({ error: "location is required" }, OpenMeteoApi.current_weather(location: " "))
  end

  test "returns an error when the location is not found" do
    with_stubbed_request_json({ "results" => [] }) do
      assert_equal(
        { error: "location not found", location: "Nowhere" },
        OpenMeteoApi.current_weather(location: "Nowhere")
      )
    end
  end

  test "returns an error when the weather service request fails" do
    with_stubbed_request_json({ "error" => "weather service request failed", "status" => 503 }) do
      assert_equal(
        { error: "weather service request failed", status: 503 },
        OpenMeteoApi.current_weather(location: "London")
      )
    end
  end

  private

  def with_stubbed_request_json(response)
    original = OpenMeteoApi.method(:request_json)
    OpenMeteoApi.define_singleton_method(:request_json) do |url, params|
      response.respond_to?(:call) ? response.call(url, params) : response
    end

    yield
  ensure
    OpenMeteoApi.define_singleton_method(:request_json) { |url, params| original.call(url, params) }
  end
end
