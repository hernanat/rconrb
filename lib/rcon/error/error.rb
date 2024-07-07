# frozen_string_literal: true

module Rcon
  # module for Rcon related errors and their messages.
  module Error
    # used for communicating that there was an issue authenticating
    # with the RCON server.
    class AuthError < StandardError
      # @return [String]
      def message
        "error authenticating with server. is your password correct?"
      end
    end

    # used for communicating that the packet type is not supported
    #
    # @attr_reader packet_type [Integer]
    class InvalidPacketTypeError < StandardError
      # @param packet_type [Symbol] the packet type
      # @return [InvalidPacketTypeError]
      def initialize(packet_type)
        @packet_type = packet_type
        super
      end

      attr_reader :packet_type

      # @return [String]
      def message
        "invalid packet_type: #{packet_type}"
      end
    end

    # used for communicating that the integer packet type code is not supported
    #
    # @attr_reader type_code [Integer]
    class InvalidResponsePacketTypeCodeError < StandardError
      # @param type_code [Integer] packet type code
      # @return [InvalidResponsePacketTypeCodeError]
      def initialize(type_code)
        @type_code = type_code
        super
      end

      attr_reader :type_code

      # @return [String]
      def message
        "invalid response packet type code: #{type_code}"
      end
    end

    # used for communicating that the server closed the connection
    class ServerClosedSocketError < StandardError
      # @return [String]
      def message
        "the server closed the connection. Do you have too many concurrent connections open?"
      end
    end

    # used for communicating that we timed out trying to read from the socket
    class SocketReadTimeoutError < StandardError
      # @return [String]
      def message
        "timed out waiting for socket to be read-ready"
      end
    end

    # used for communicating that we timed out trying to write to the socket
    class SocketWriteTimeoutError < StandardError
      # @return [String]
      def message
        "timed out waiting for socket to be write-ready"
      end
    end

    # used for communicating that the response type of the packet is unsupported
    #
    # @attr_reader response_type [Symbol]
    class UnsupportedResponseTypeError < StandardError
      # @param response_type [Symbol] the response type
      # @return [UnsupportedResponseTypeError]
      def initialize(response_type)
        @response_type = response_type
      end

      attr_reader :response_type

      # @return [String]
      def message
        "unsupported response type: #{response_type}"
      end
    end
  end
end
