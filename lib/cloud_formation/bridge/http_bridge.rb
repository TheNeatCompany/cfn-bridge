require 'faraday'
require 'faraday_middleware'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

module CloudFormation
  module Bridge
    class HttpBridge

      class << self

        def put(url, data)
          connection = Faraday.new do |f|
            f.request :json
            f.request :retry, max: 2, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2

            f.response :raise_error
            f.response :json, content_type: /javascript|json/

            f.adapter :typhoeus
          end

          connection.put(url, data, 'Content-Type' => '')
        end

      end

    end
  end
end