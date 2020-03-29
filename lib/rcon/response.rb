module Rcon
  class Response
    RESPONSE_TYPE = {
      SERVERDATA_AUTH_RESPONSE: 2,
      SERVERDATA_RESPONSE_VALUE: 0
    }.freeze

    def self.from(id:, type:, body:)
      case type
      when RESPONSE_TYPE[:SERVERDATA_AUTH_RESPONSE]
        AuthResponse.new(id: id, type: type, body: body)
      when RESPONSE_TYPE[:SERVERDATA_RESPONSE_VALUE]
        CommandResponse.new(id: id, type: type, body: body)
      else
        raise "unsupported response type: #{type}"
      end
    end

    def initialize(id:, type:, body:)
      @id = id
      @type = type
      @body = body
    end

    attr_reader :id, :type, :body
  end

  class AuthResponse < Response
    AUTH_FAILURE_RESPONSE = -1
    def success?
      id != AUTH_FAILURE_RESPONSE
    end
  end

  class CommandResponse < Response

  end
end
