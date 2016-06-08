require "net/http"
require "cuba"
require "cuba/render"
require "oj"
require "geocoder"

Cuba.use Rack::Static, urls: %w(/css /js /img), root: "public"
Cuba.plugin Cuba::Render

NOMADTRIPS = URI("https://nomadtrips.co/godfoca.json".freeze)

Cuba.define do
  def info
    @_info ||= Oj.load(Net::HTTP.get(NOMADTRIPS))
  end

  def here_is_foca
    @_here ||= info["location"]["now"]
  end

  def city
    city_location = Geocoder.search(here_is_foca).first
    latitude, longitude = city_location.coordinates

    { latitude:  latitude, longitude: longitude, name: here_is_foca }
  end

  def json_call?
    req.content_type == "application/json"
  end

  on json_call? || "where" do
    res.write city.to_json
  end

  on root do
    res.write partial("home")
  end
end

run Cuba
