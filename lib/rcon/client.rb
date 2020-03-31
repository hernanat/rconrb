require "rcon/packet"
require "rcon/response"
require "rcon/socket_wrapper"
require "socket"
require "securerandom"

module Rcon
  # Basic client for executing commands on your server remotely using the Source RCON protocol.
  # See {https://developer.valvesoftware.com/wiki/Source_RCON_Protocol here} for more details.
  #
  # This is intended to be flexible enough to suit the needs of various flavors of RCON (for
  # example, Minecraft).
  #
  # See individual method summaries for more information.
  class Client
    # Instantiates an {Client}.
    #
    # @param host [String] IP address of the server running RCON
    # @param port [Integer] RCON port
    # @param password [String] RCON password
    # @return [Client]
    def initialize(host:, port:, password:)
      @host = host
      @port = port
      @password = password
      @socket = nil
    end

    # Opens a TCP socket and authenticates with RCON.
    #
    # According to the RCON spec, the server will respond to an authentication request with a
    # SERVERDATA_RESPONSE_VALUE packet, followed by a SERVERDATA_AUTH_RESPONSE packet by
    # default.
    #
    # However, this is not the case in every implementation (looking at you Minecraft). For the
    # sake of being flexible, we include a param which allows us to enable / disable this default behavior (see below).
    #
    # It is not recommended to call this method more than once before ending the session.
    #
    # @param ignore_first_packet [Boolean]
    # @return [AuthResponse]
    # @raise [Error::AuthError] if authentication fails
    def authenticate!(ignore_first_packet: true)
      packet_id = SecureRandom.rand(1000)
      auth_packet = Packet.new(packet_id, :SERVERDATA_AUTH, password)
      @socket = SocketWrapper.new(TCPSocket.open(host, port))
      socket.deliver_packet(auth_packet)
      read_packet_from_socket if ignore_first_packet

      read_packet_from_socket.
        then { |packet| Response.from_packet(packet) }.
        tap { |response| raise Error::AuthError unless response.success? }
    end

    # Execute the given command.
    #
    # Some commands require their responses to be sent across several packets because
    # they are larger than the maximum (default) RCON packet size of 4096 bytes.
    #
    # In order to deal with this, we send an additional "trash" packet immediately
    # following the initial command packet. SRCDS guarantees that requests are processed
    # in order, and the subsequent responses are also in order, so we use this fact to
    # append the packet bodies to the result on the client side until we see the trash
    # packet id.
    #
    # Many commands won't require a segmented response, so we disable this behavior by
    # default. You can enable it if you'd like using the option describe below.
    #
    # Additionally, some implementations of RCON servers (MINECRAFT) cannot handle two 
    # packets in quick succession, so you may want to wait a short duration (i.e. <= 1 second)
    # before sending the trash packet. We give the ability to do this using the
    # wait option described below.
    #
    # @param [Hash] opts options for executing the command
    # @option opts [Boolean] :expect_segmented_response follow segmented response logic described above if true
    # @option opts [Integer] :wait seconds to wait before sending trash packet (i.e. Minecraft 😡)
    # @return [CommandResponse]
    def execute(command, opts = {})
      packet_id = SecureRandom.rand(1000)
      socket.deliver_packet(Packet.new(packet_id, :SERVERDATA_EXECCOMMAND, command))
      trash_packet_id = build_and_send_trash_packet(opts) if opts[:expect_segmented_response]
      build_response(trash_packet_id)
    end

    # Close the TCP socket and end the RCON session.
    # @return [nil]
    def end_session!
      @socket = socket.close
    end

    private

    attr_reader :host, :port, :password, :socket

    def build_response(trash_packet_id)
      if trash_packet_id.nil?
        read_packet_from_socket.then { |p| Response.from_packet(p) }
      else
        build_segmented_response(trash_packet_id, read_packet_from_socket)
      end
    end

    def build_segmented_response(trash_packet_id, first_segment)
      next_segment = read_packet_from_socket
      response = Response.from_packet(first_segment)
      loop do
        break if next_segment.id == trash_packet_id
        response.body = "#{response.body}#{next_segment.body}"
        next_segment = read_packet_from_socket
      end
      response
    end

    def build_and_send_trash_packet(opts = {})
      # some RCON implementations (I'm looking at you Minecraft)
      # blow up if you send successive packets too quickly
      # the work around (currently) is to allow the server some
      # time to catch up. Note that this isn't an exact science.
      wait = opts[:wait]
      SecureRandom.rand(1000).tap do |packet_id|
        sleep(wait) if wait
        socket.deliver_packet(Packet.new(packet_id, 0, ""))
      end
    end

    def read_packet_from_socket
      Packet.read_from_socket_wrapper(socket)
    end
  end
end
