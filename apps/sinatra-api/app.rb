require "sinatra"
require "json"

set :bind, "0.0.0.0"
set :port, 4567

get "/health" do
  content_type :json
  { status: "ok", service: "api", time: Time.now.utc.iso8601 }.to_json
end
