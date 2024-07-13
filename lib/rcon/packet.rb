module Rcon
  # Data structure representing packets sent to / received from RCON server.
  class Packet
    INTEGER_PACK_DIRECTIVE = "l<".freeze
    STR_PACK_DIRECTIVE = "a".freeze
    PACKET_PACK_DIRECTIVE = "#{INTEGER_PACK_DIRECTIVE}2#{STR_PACK_DIRECTIVE}*#{STR_PACK_DIRECTIVE}".freeze
    ENCODING = Encoding::ASCII
    TRAILER = "\x00".freeze
    INT_BYTE_SIZE = 4
    TRAILER_BYTE_SIZE = 1 

    # Types of packets that the server expects to receive.
    #
    # The keys correspond with the Source RCON spec names, the values correspond with
    # what the server expects to see in the type segment of a packet.
    REQUEST_PACKET_TYPE = {
      SERVERDATA_AUTH: 3,
      SERVERDATA_EXECCOMMAND: 2
    }.freeze

    # Types of packets that the client can expect to receive
    # back from the server.
    #
    # The keys correspond with the Source RCON spec names, the values correspond with
    # what the client expects to see in the type segment of a packet.
    RESPONSE_PACKET_TYPE = {
      SERVERDATA_AUTH_RESPONSE: 2,
      SERVERDATA_RESPONSE_VALUE: 0
    }.freeze

    private_constant(
      :INTEGER_PACK_DIRECTIVE, :STR_PACK_DIRECTIVE, :PACKET_PACK_DIRECTIVE,
      :ENCODING, :TRAILER, :INT_BYTE_SIZE, :TRAILER_BYTE_SIZE
    )

    # Read a packet from the given {SocketWrapper}.
    #
    # @param socket_wrapper [SocketWrapper]
    # @return [Packet]
    # @raise [Error::SocketReadTimeoutError] if timeout occurs while waiting to read from socket
    def self.read_from_socket_wrapper(socket_wrapper)
      if socket_wrapper.ready_to_read?
        size = socket_wrapper.recv(INT_BYTE_SIZE)&.unpack(INTEGER_PACK_DIRECTIVE)&.first
        if size.nil?
          raise Error::ServerClosedSocketError
        end
        id_and_type_length = 2 * INT_BYTE_SIZE
        body_length = size - id_and_type_length - (2 * TRAILER_BYTE_SIZE) # ignore trailing nulls

        payload = socket_wrapper.recv(size)
        if payload.nil?
          raise Error::ServerClosedSocketError
        end
        id, type_int = payload[0...id_and_type_length].unpack("#{INTEGER_PACK_DIRECTIVE}*")
        body = payload[id_and_type_length..].unpack("#{STR_PACK_DIRECTIVE}#{body_length}").first
        type = RESPONSE_PACKET_TYPE.key(type_int) || raise(Error::InvalidResponsePacketTypeCodeError.new(type_int))

        new(id, RESPONSE_PACKET_TYPE.key(type_int), body)
      end
    end

    # Instantiates a {Packet}
    #
    # @param id [Integer] the packet id
    # @param type [Symbol] see {REQUEST_PACKET_TYPE} and {RESPONSE_PACKET_TYPE} keys
    # @param body [String] the packet body
    # @return [Packet]
    def initialize(id, type, body)
      @id = id
      @type = type
      @body = body
    end

    # Compares two objects to see if they are equal
    # 
    # Returns true if other is a Packet and attributes match self, false otherwise.
    # @param other [Packet, Object]
    # @return [Boolean]
    def ==(other)
      eql?(other)
    end

    # Compares two objects to see if they are equal
    # Returns true if other is a Packet and attributes match self, false otherwise.
    #
    # @param other [Packet, Object]
    # @return [Boolean]
    def eql?(other)
      if other.is_a?(Packet)
        id == other.id && type == other.type && body == other.body
      else
        false
      end
    end

    # Converts the packet into an ASCII-encoded RCON Packet string for transmitting
    # to the server.
    #
    # @return [String]
    def to_s
      [id, type_to_i, "#{body}#{TRAILER}", TRAILER].pack(PACKET_PACK_DIRECTIVE).then do |packet_str|
        "#{[packet_str.length].pack(INTEGER_PACK_DIRECTIVE)}#{packet_str}".force_encoding(ENCODING)
      end
    end

    # Get the integer representation of the packet's type, which is used in the string
    # representation of the packet.
    # 
    # @return [Integer]
    # @raise [Error::InvalidPacketTypeError] if the packet type is unknown / invalid.
    def type_to_i
      type_sym = type.to_sym
      case type_sym
      when ->(t) { REQUEST_PACKET_TYPE.keys.include?(t) }
        REQUEST_PACKET_TYPE[type_sym]
      when ->(t) { RESPONSE_PACKET_TYPE.keys.include?(t) }
        RESPONSE_PACKET_TYPE[type_sym]
      else
        raise Error::InvalidPacketTypeError.new(type)
      end
    end

    attr_reader :id, :type, :body
  end
end
