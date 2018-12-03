# frozen_string_literal: true

require 'json'
require 'net/http'
require 'openssl'

class HerokuClient
  def initialize(api_key: ENV.fetch('HEROKU_API_KEY', ''),
                 api_host: 'api.heroku.com')
    @api_key = api_key
    @api_host = api_host
  end

  attr_reader :api_key, :api_host
  private :api_key
  private :api_host

  def get(path)
    request(Net::HTTP::Get.new(path))
  end

  def post(body, path)
    req = Net::HTTP::Post.new(path)
    req.body = body
    request(req)
  end

  def patch(body, path)
    req = Net::HTTP::Patch.new(path)
    req.body = body
    request(req)
  end

  def stream(uri)
    start_params = [uri.host, uri.port]
    if uri.scheme == 'https'
      start_params += [
        use_ssl: true,
        verify_mode: OpenSSL::SSL::VERIFY_PEER
      ]
    end

    Net::HTTP.start(*start_params) do |http|
      req = Net::HTTP::Get.new(uri)
      req['Accept'] = 'application/vnd.heroku+json; version=3'
      req['Authorization'] = "Bearer #{api_key}"
      req['Content-Type'] = 'application/json'

      http.request(req) do |response|
        return false unless response.is_a?(Net::HTTPSuccess)

        response.read_body { |c| warn c }
      end
    end

    true
  end

  def request(req, headers: {})
    req['Accept'] = 'application/vnd.heroku+json; version=3'
    req['Authorization'] = "Bearer #{api_key}"
    req['Content-Type'] = 'application/json'

    http = Net::HTTP.new(api_host, 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    headers.each do |key, value|
      request[key] = value
    end

    response = http.request(req)

    raise response.body unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end
