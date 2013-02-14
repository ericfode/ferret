require 'sinatra'
r = Random.new
get '/' do 
  sleep 1
  "hello world"
end