require 'dollars'

run Rack::URLMap.new \
  "/"       => Sinatra::Application