require 'logger'

module CloudFormation
  module Bridge
    module Util
      LOGGER = Logger.new(STDOUT)

      def self.logger
        @logger ||= LOGGER
      end

    end
  end
end