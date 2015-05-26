require "cuba"
require "cuba/render"
require "instagram"
require "geocoder"

Cuba.use Rack::Static, urls: %w(/css /js /img), root: "public"
Cuba.plugin Cuba::Render

Cuba.define do
  settings[:foca_id] = ENV["FOCA_INSTAGRAM_ID"]
  settings[:access_token] = ENV["INSTAGRAM_ACCESS_TOKEN"]

  def here_is_foca
    client = Instagram.client(access_token: settings[:access_token])
    foca_media = client.user_recent_media(settings[:foca_id])
    # Default is Montevideo
    last_known_location = Hashie::Mash.new(latitude: "-34.905944", longitude: "-56.191556")

    foca_media.each do |pic|
      if pic.location
        last_known_location = pic.location
        break
      end
    end

    last_known_location
  end

  def city(coordinates)
    here = Geocoder.search("#{coordinates.latitude},#{coordinates.longitude}")
    city_info = here.first
    # Use city coordinates and no the Instagram ones. We want to know where is
    # foca not send him a nuclear strike.
    city_location = Geocoder.search(city_info.city).first
    latitude, longitude = city_location.coordinates

    {
      latitude:  latitude,
      longitude: longitude,
      name:      city_info.city
    }
  end

  def json_call?
    req.content_type == "application/json"
  end

  on json_call? || "where" do
    res.write city(here_is_foca).to_json
  end

  on root do
    res.write render("views/home.erb")
  end
end

run Cuba
