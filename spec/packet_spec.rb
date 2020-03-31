RSpec.describe Rcon::Packet do
  include TcpHelper

  describe ".read_from_socket_wrapper" do
    it "instantiates a new `Rcon::Packet` from data read from the given socket wrapper" do
      response = "\x17\x00\x00\x00\x9A\x02\x00\x00\x00\x00\x00\x00test response\x00\x00"
      server = mock_server_response(response)

      wrapper = Rcon::SocketWrapper.new(TCPSocket.open("0.0.0.0", 2000))

      expect(Rcon::Packet.read_from_socket_wrapper(wrapper)).to eql(
        Rcon::Packet.new(666, :SERVERDATA_RESPONSE_VALUE, "test response")
      )

      server.close
    end

    it "raises an `Rcon::Error::InvalidResponsePacketTypeCodeError` for invalid integer response type codes" do
      response = "\x17\x00\x00\x00\x9A\x02\x00\x00\x05\x00\x00\x00test response\x00\x00"
      server = mock_server_response(response)

      wrapper = Rcon::SocketWrapper.new(TCPSocket.open("0.0.0.0", 2000))

      expect { Rcon::Packet.read_from_socket_wrapper(wrapper) }.to raise_error(
          an_instance_of(Rcon::Error::InvalidResponsePacketTypeCodeError).and having_attributes(type_code: 5)
        )

      server.close
    end

    it "raises an `Rcon::Error::SocketReadTimeoutError` if the socket is unavailable for reading" do
      stub_const("Rcon::SocketWrapper::TIMEOUT", 0)
      server = TCPServer.new("0.0.0.0", 2000)

      wrapper = Rcon::SocketWrapper.new(TCPSocket.open("0.0.0.0", 2000))

      expect { Rcon::Packet.read_from_socket_wrapper(wrapper) }.to raise_error(Rcon::Error::SocketReadTimeoutError)

      server.close
    end
  end

  describe "#to_s" do
    it "returns an ASCII-encoded RCON packet string" do
      packet = Rcon::Packet.new(666, :SERVERDATA_EXECCOMMAND, "list")
      id_str = "\x9A\x02\x00\x00"
      type_str = "\x02\x00\x00\x00"
      body_str = "list\x00"
      trailer = "\x00"
      base_str = "#{id_str}#{type_str}#{body_str}#{trailer}"
      size_str = [base_str.length].pack("l<")
      expected_str = "#{size_str}#{base_str}".force_encoding(Encoding::ASCII)

      packet_str = packet.to_s

      expect(packet_str).to eql(expected_str)
      expect(packet_str.encoding).to eql(Encoding::ASCII)
    end
  end

  describe "#==" do
    it "is true if the packet attributes are the same" do
      p1 = Rcon::Packet.new(666, :SERVERDATA_EXECCOMMAND, "list")
      p2 = Rcon::Packet.new(666, :SERVERDATA_EXECCOMMAND, "list")

      expect(p1 == p2).to eql(true)
    end
  end

  describe "#eql?" do
    it "is true if the packet attributes are the same" do
      p1 = Rcon::Packet.new(666, :SERVERDATA_EXECCOMMAND, "list")
      p2 = Rcon::Packet.new(666, :SERVERDATA_EXECCOMMAND, "list")

      expect(p1.eql?(p2)).to eql(true)
    end
  end

  describe "#type_to_i" do
    context "request packet" do
      it "returns the integer value associated with the packet type" do
        packet = Rcon::Packet.new(666, :SERVERDATA_EXECCOMMAND, "list")

        expect(packet.type_to_i).to eql(2)
      end
    end

    context "response packet" do
      it "returns the integer value assocaited with the packet type" do
        packet = Rcon::Packet.new(666, :SERVERDATA_RESPONSE_VALUE, "foo")

        expect(packet.type_to_i).to eql(0)
      end
    end

    context "unknown packet type" do
      it "raises an Rcon::Error::InvalidPacketTypeError" do
        packet = Rcon::Packet.new(666, :BAD, "foo")

        expect { packet.type_to_i }.to raise_error(
          an_instance_of(Rcon::Error::InvalidPacketTypeError).and having_attributes(packet_type: :BAD)
        )
      end
    end
  end
end
