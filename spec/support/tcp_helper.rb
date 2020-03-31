module TcpHelper
  def mock_server_response(response)
    server = TCPServer.new("0.0.0.0", 2000)

    Thread.new do
      client = server.accept
      client.write(response.force_encoding(Encoding::ASCII))
    end

    server
  end

  def mock_server_auth_response(request_packet_id, success: true, initial_response_value_packet: true)
    server = TCPServer.new("0.0.0.0", 2000)
    id = success ? request_packet_id : -1
    response_packet = Rcon::Packet.new(id, :SERVERDATA_AUTH_RESPONSE, "").to_s

    Thread.new do
      client = server.accept
      client.write(initial_response_packet_str(request_packet_id)) if initial_response_value_packet
      client.write(response_packet)
    end
    
    server
  end

  private

  def initial_response_packet_str(id)
    Rcon::Packet.new(id, :SERVERDATA_RESPONSE_VALUE, "").to_s
  end
end
