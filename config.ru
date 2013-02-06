require "sinatra"

set :static, true

helpers do
  def manifests
    Dir["./public/manifests/*.json"].map { |m| m.split("/")[-1].split(".")[0] }.sort.reverse
  end

  def metrics_url
    ENV["METRICS_URL"]
  end

  def metric_token
    ENV["METRICS_TOKEN"]
  end
end

get "/" do
  erb :index
end

get "/health" do
  ""
end


run Sinatra::Application
