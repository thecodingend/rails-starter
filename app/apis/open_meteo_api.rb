require "json"
require "net/http"
require "uri"

class OpenMeteoApi
  GEOCODING_URL = "https://geocoding-api.open-meteo.com/v1/search"
  FORECAST_URL = "https://api.open-meteo.com/v1/forecast"

  CURRENT_FIELDS = %w[
    temperature_2m
    apparent_temperature
    relative_humidity_2m
    precipitation
    weather_code
    wind_speed_10m
  ].freeze

  def self.current_weather(location:)
    query = location.to_s.strip
    return { error: "location is required" } if query.blank?

    place = geocode(query)
    return { error: place["error"], status: place["status"] } if place&.key?("error")
    return { error: "location not found", location: query } unless place

    forecast = request_json(FORECAST_URL, {
      latitude: place.fetch("latitude"),
      longitude: place.fetch("longitude"),
      current: CURRENT_FIELDS.join(","),
      timezone: "auto"
    })
    return { error: forecast["error"], status: forecast["status"] } if forecast.key?("error")

    format_weather(place, forecast)
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError => error
    { error: "weather service unavailable", detail: error.class.name }
  end

  def self.geocode(query)
    response = request_json(GEOCODING_URL, {
      name: query,
      count: 1,
      language: "en",
      format: "json"
    })
    return response if response.key?("error")

    response.fetch("results", []).first
  end

  def self.request_json(url, params)
    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 5

    response = http.get(uri.request_uri)
    return { "error" => "weather service request failed", "status" => response.code.to_i } unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def self.format_weather(place, forecast)
    current = forecast.fetch("current", {})
    units = forecast.fetch("current_units", {})
    weather_code = current["weather_code"]

    {
      source: "Open-Meteo",
      location: {
        name: place["name"],
        country: place["country"],
        admin1: place["admin1"],
        latitude: place["latitude"],
        longitude: place["longitude"],
        timezone: forecast["timezone"] || place["timezone"]
      }.compact,
      current: {
        time: current["time"],
        temperature: value_with_unit(current, units, "temperature_2m"),
        feels_like: value_with_unit(current, units, "apparent_temperature"),
        humidity: value_with_unit(current, units, "relative_humidity_2m"),
        precipitation: value_with_unit(current, units, "precipitation"),
        wind_speed: value_with_unit(current, units, "wind_speed_10m"),
        weather: {
          code: weather_code,
          description: weather_description(weather_code)
        }.compact
      }.compact
    }
  end

  def self.value_with_unit(values, units, key)
    return unless values.key?(key)

    {
      value: values[key],
      unit: units[key]
    }.compact
  end

  def self.weather_description(code)
    case code
    when 0 then "clear sky"
    when 1 then "mainly clear"
    when 2 then "partly cloudy"
    when 3 then "overcast"
    when 45, 48 then "fog"
    when 51, 53, 55 then "drizzle"
    when 56, 57 then "freezing drizzle"
    when 61, 63, 65 then "rain"
    when 66, 67 then "freezing rain"
    when 71, 73, 75 then "snow fall"
    when 77 then "snow grains"
    when 80, 81, 82 then "rain showers"
    when 85, 86 then "snow showers"
    when 95 then "thunderstorm"
    when 96, 99 then "thunderstorm with hail"
    end
  end
end
