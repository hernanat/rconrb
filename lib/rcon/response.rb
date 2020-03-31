module Rcon
  # wraps the response we receive from the server. It might not be obvious at
  # first why have this additional datastructure. There are two main motivations.
  #
  # First, to separate how we deal with an {AuthResponse} vs a {CommandResponse}.
  #
  # Secondly, when we are dealing with segmented responses, instead of modifying
  # the first packet in place to add subsequent parts of the body, we modify the
  # {Response} object corresponding with the total response. i.e. a {Response} is
  # a sum of {Packet}s.
  #
  # @attr_reader id [Integer] the initial request packet id corresponding to the response
  #   (except maybe for {AuthResponse}, see {AuthResponse#success?}
  # @attr_reader type [Symbol] the type of response; see {Packet::RESPONSE_PACKET_TYPE}
  # @attr body [String] the response body, which may be the concatenation of
  #   the bodies of several packets.
  class Response
    # instantiate an instance of a {Response} subclass given a packet.
    #
    # @param packet [Packet] the packet
    # @return [AuthResponse, CommandResponse]
    def self.from_packet(packet)
      params = { id: packet.id, type: packet.type, body: packet.body }
      case packet.type
      when :SERVERDATA_AUTH_RESPONSE
        AuthResponse.new(**params)
      when :SERVERDATA_RESPONSE_VALUE
        CommandResponse.new(**params)
      else
        raise Error::UnsupportedResponseTypeError.new(packet.type)
      end
    end

    # instantiate a new {Response}
    #
    # @param id [Integer] the id of the initial request packet that the response
    #   corresponds to
    # @param type [Symbol] the response type; see {Packet::RESPONSE_PACKET_TYPE}
    # @param body [String] the response body
    def initialize(id:, type:, body:)
      @id = id
      @type = type
      @body = body
    end

    attr_reader :id, :type
    attr_accessor :body
  end

  # the {Response} subclass corresponding with authentication response packets
  # from the server.
  class AuthResponse < Response
    # when authentication fails, the ID field of the auth respone packet will
    # be set to -1
    AUTH_FAILURE_RESPONSE = -1

    # determines whether or not authentication has succeeded.
    #
    # according to the RCON spec, when authentication fails, -1 is returned in the id field of the packet.
    # @return [Boolean]
    def success?
      id != AUTH_FAILURE_RESPONSE
    end
  end

  # the {Response} subclass corresponding with response packets from the server
  # that result from executing a command
  class CommandResponse < Response; end
end
