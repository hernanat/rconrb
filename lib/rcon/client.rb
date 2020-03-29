require "rcon/response"
require "socket"
require "securerandom"

module Rcon
  class Client
    INTEGER_PACK_DIRECTIVE = "l<".freeze
    STR_PACK_DIRECTIVE = "a".freeze
    PACK_DIRECTIVE = "#{INTEGER_PACK_DIRECTIVE}2a*a".freeze
    ENCODING = Encoding::ASCII
    TRAILER = "\x00".freeze
    INT_BYTE_SIZE = 4
    TRAILER_BYTE_SIZE = 1 
    TIMEOUT = 10 # 10 seconds

    PACKET_TYPE = {
      SERVERDATA_AUTH: 3,
      SERVERDATA_EXECCOMMAND: 2
    }.freeze

    def initialize(host:, port:, password:, encoding: ENCODING, trailer: TRAILER)
      @host = host
      @port = port
      @password = password
      @encoding = encoding
      @trailer = trailer.encode(encoding)
      @tcp_socket = nil
    end

    def authorize!(packet_id: 0xDEAD1, expect_first_packet_empty: true)
      build_packet(packet_id, PACKET_TYPE[:SERVERDATA_AUTH], password).then do |auth_packet|
        @tcp_socket = TCPSocket.open(host, port)
        tcp_socket.send(auth_packet, 0)
        read_response_data if expect_first_packet_empty
        raise "error authenticating" unless Response.from(**read_response_data).success?
        self
      end
    end

    def end_session!
      @tcp_socket = tcp_socket.close
    end

    def execute(command, opts = {})
      packet_id = SecureRandom.rand(1000)
      build_packet(packet_id, PACKET_TYPE[:SERVERDATA_EXECCOMMAND], command).then do |packet|
        send_packet(packet)
        trash_packet_id = build_and_send_trash_packet(opts) if opts[:expect_segmented_response]
        build_response(trash_packet_id)
      end
    end

    private

    attr_reader :host, :port, :password, :encoding, :trailer, :tcp_socket

    def build_response(trash_packet_id)
      if trash_packet_id.nil?
        read_response_data
      else
        build_segmented_response(trash_packet_id, read_response_data)
      end.then { |result| Response.from(**result) }
    end

    def build_segmented_response(trash_packet_id, base_response)
      next_segment = read_response_data
      body = base_response[:body]
      loop do
        break if next_segment[:id] == trash_packet_id
        body = "#{body}#{next_segment[:body]}"
        next_segment = read_response_data
      end
      base_response.tap { |h| h[:body] = body }
    end

    def build_and_send_trash_packet(opts = {})
      # some RCON implementations (I'm looking at you Minecraft)
      # blow up if you send successive packets too quickly
      # the work around (currently) is to allow the server some
      # time to catch up. Note that this isn't an exact science.
      sleep = opts[:sleep]
      SecureRandom.rand(1000).tap do |packet_id|
        sleep(sleep) if sleep
        send_packet(build_packet(packet_id, 0, ""))
      end
    end

    def send_packet(packet)
      if socket_ready_to_write?
        tcp_socket.send(packet, 0)
      end
    end

    def socket_ready_to_write?
      IO.select(nil, [tcp_socket], nil, TIMEOUT).tap do |io|
        raise "timed out waiting for socket to be write-ready" if io.nil?
      end
    end

    def socket_ready_to_read?
      IO.select([tcp_socket], nil, nil, TIMEOUT).tap do |io|
        raise "timed out waiting for socket to be read-ready" if io.nil?
      end
    end

    def read_response_data
      if socket_ready_to_read?
        size = tcp_socket.recv(INT_BYTE_SIZE).unpack(INTEGER_PACK_DIRECTIVE).first
        id_and_type_length = 2 * INT_BYTE_SIZE
        body_length = size - id_and_type_length - (2 * TRAILER_BYTE_SIZE) # ignore trailing null chars

        payload = tcp_socket.recv(size)
        id, type = payload[0...id_and_type_length].unpack("#{INTEGER_PACK_DIRECTIVE}*")
        body = payload[id_and_type_length..].unpack("#{STR_PACK_DIRECTIVE}#{body_length}").first

        { id: id, type: type, body: body }
      end
    end

    def build_packet(packet_id, packet_type, packet_body)
      encoded_body = "#{packet_body.encode(encoding)}#{trailer}"
      [packet_id, packet_type, encoded_body, trailer].pack(PACK_DIRECTIVE).then do |packet|
        "#{[packet.length].pack(INTEGER_PACK_DIRECTIVE)}#{packet}"
      end
    end 
  end
end
