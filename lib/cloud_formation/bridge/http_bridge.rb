require 'faraday'
require 'faraday_middleware'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'faraday_curl'
require 'cloud_formation/bridge/util'

module CloudFormation
  module Bridge
    class HttpBridge

      class << self

        def put(url, data)
          connection = Faraday.new do |f|
            f.request :json
            f.request :curl, Util::LOGGER , :info
            f.request :retry, max: 2, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2

            f.response :raise_error
            f.response :json, content_type: /javascript|json/

            f.adapter :typhoeus
          end

          response = connection.put(url, data, 'Content-Type' => '')

          Util::LOGGER.info("S3 response was #{response.inspect}")

          response
        end

      end

    end
  end
end