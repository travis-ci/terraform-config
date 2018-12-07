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

  def wait(heroku_app, timeout: 120)
    c = 0

    loop do
      return true if get("/apps/#{heroku_app}")
      return false if c >= timeout

      sleep 10
      c += 10
    end

    true
  end

  def deploy(repo_slug, heroku_app, version)
    warn "\nDeploying #{repo_slug} #{version} to #{heroku_app}"

    response = post(
      JSON.generate(
        'source_blob' => {
          'url' => "https://github.com/#{repo_slug}/archive/#{version}.tar.gz",
          'version' => version
        }
      ),
      "/apps/#{heroku_app}/builds"
    )

    raise 'Could not request a deployment' if response.nil?

    warn "\nStreaming deploy output"

    raise 'Could not stream deployment output' unless stream(URI(response.fetch('output_stream_url')))
  end

  def scale(heroku_app, ps_scales)
    Array(ps_scales).each do |ps_scale|
      formation = parse_formation(ps_scale)
      response = patch(
        JSON.generate(
          'quantity' => formation.fetch(:qty),
          'size' => formation.fetch(:size)
        ),
        "/apps/#{heroku_app}/formation/#{formation.fetch(:type)}"
      )
      raise "Could not scale #{heroku_app} #{ps_scales.inspect}" if response.nil?

      warn "---> scaled #{heroku_app} #{ps_scale}:"
      warn JSON.pretty_generate(response)
    end
  end

  def parse_formation(ps_scale)
    ret = {
      type: '',
      qty: 0,
      size: ''
    }

    parts = ps_scale.split('=', 2)
    ret[:type] = parts.fetch(0)

    subparts = parts.fetch(1).split(':', 2)
    ret[:qty] = Integer(subparts.fetch(0))
    ret[:size] = subparts.fetch(1).strip

    ret
  end

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
