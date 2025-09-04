require 'webrick'
include WEBrick

# A simple script you can run locally to run the site locally for debugging
# usage: `ruby serve.rb`

server = HTTPServer.new(:Port => 8000,  :DocumentRoot => Dir.pwd)
trap("INT"){ server.shutdown }
server.start