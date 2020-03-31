require "delegate"

module Rcon
  # Simple wrapper to give some convenience methods around sockets.
  class SocketWrapper < SimpleDelegator
    TIMEOUT = 5 

    private_constant :TIMEOUT

    # deliver the packet to the server if the socket is ready to
    # be written.
    #
    # @param packet [Packet] the packet to be delivered
    # @return [Integer] the number of bytes sent
    # @raise [Error::SocketWriteTimeoutError] if a timeout occurs while waiting to write to socket
    def deliver_packet(packet)
      write(packet.to_s) if ready_to_write?
    end

    # check if socket is ready to read
    #
    # @return [Array] containing socket in first subarray if socket is ready to read
    # @raise [Error::SocketReadTimeoutError] if timeout occurs
    def ready_to_read?
      IO.select([__getobj__], nil, nil, TIMEOUT).tap do |io|
        raise Error::SocketReadTimeoutError if io.nil?
      end
    end

    # check if socket is ready to write
    #
    # @return [Array] containing socket in second subarray if socket is ready to write
    # @raise [Error::SocketReadTimeoutError] if timeout occurs
    def ready_to_write?
      IO.select(nil, [__getobj__], nil, TIMEOUT).tap do |io|
        raise Error::SocketWriteTimeoutError if io.nil?
      end
    end
  end
end
