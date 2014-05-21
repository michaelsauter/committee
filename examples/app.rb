require "committee"
require "multi_json"
require "securerandom"
require "sinatra/base"

class App < Sinatra::Base
  SCHEMA = MultiJson.decode(File.read("schema.json"))

  # The request validator verifies that the required input parameters (and no
  # unknown input parameters) are included with the request and that they are
  # of the right types.
  use Committee::Middleware::RequestValidation, schema: SCHEMA

  # The stubbing middleware generates sample responses based on the schema. The
  # :call option indicates that it should still call down to the underlying
  # Sinatra handlers if they exist.
  #
  # Note that the stub's response can be modified or suppressed. See the POST
  # /apps and PATCH /apps/:id handlers below for examples.
  use Committee::Middleware::Stub, call: true, schema: SCHEMA

  # The response validator checks that responses from within the stack are
  # compliant with the JSON schema. It's normally used for verification in
  # tests, but here we can use it to check that our changes to the stub's
  # responses are still compliant with our schema.
  use Committee::Middleware::ResponseValidation, schema: SCHEMA

  # This handler is called into, but its response is ignored.
  get "/apps" do
  end

  # This handler suppresses the stubbed response and returns its own.
  post "/apps" do
    env["committee.suppress"] = true
    content_type :json
    status 201
    id = SecureRandom.uuid
    JSON.pretty_generate({
      id: id,
      name: "app-#{id}",
    })
  end

  get "/apps/:id" do |id|
  end

  # This parameter mixes in some custom information from the request into the
  # default stubbed response and responds with that.
  patch "/apps/:id" do |id|
    env["committee.response"].merge!(env["committee.params"])
  end

  delete "/apps/:id" do |id|
  end
end

if __FILE__ == $0
  App.run! port: 5000
end
