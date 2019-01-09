# encoding: UTF-8
# frozen_string_literal: true

class Rack::Attack
  limit = ENV['SOMBRA_RATE_LIMIT_REQUESTS'] || 300
  period = ENV['SOMBRA_RATE_LIMIT_PERIOD_IN_S'] || 10

  # do not throttle on private nets
  #safelist_ip("10.0.0.0/8")
  #safelist_ip("172.16.0.0/12")
  #safelist_ip("192.168.0.0/16")

  throttle('req/ip', :limit => limit.to_i, :period => period.to_i.seconds) do |req|
    req.ip
  end

  Rack::Attack.throttled_response = lambda do |env|
    now = Time.now.utc
    match_data = env['rack.attack.match_data']

    headers = {
      'X-RateLimit-Limit' => match_data[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => (now + (match_data[:period] - now.to_i % match_data[:period])).to_s
    }

    [ 429, headers, ["Throttled"]]
  end
end
