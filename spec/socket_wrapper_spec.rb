RSpec.describe Rcon::SocketWrapper do
  include TcpHelper

  describe "#deliver_packet" do
    context "socket is ready to be written" do
      it "writes the packet string to the socket" do
        server = mock_server_response("")
        socket = TCPSocket.open("0.0.0.0", 2000)
        wrapper = Rcon::SocketWrapper.new(socket)
        packet = Rcon::Packet.new(666, :SERVERDATA_EXECCOMMAND, "list")
        allow(socket).to receive(:write).with(packet.to_s)

        wrapper.deliver_packet(packet)

        expect(socket).to have_received(:write).with(packet.to_s)

        server.close
      end
    end

    context "socket is not ready to be written" do
      it "raises a `Error::SocketWriteTimeoutError`" do
        stub_const("Rcon::SocketWrapper::TIMEOUT", 0)
        server = TCPServer.new("0.0.0.0", 2000)
        packet = Rcon::Packet.new(666, :SERVERDATA_EXECCOMMAND, "list")
        socket = TCPSocket.open("0.0.0.0", 2000)
        allow(IO).to receive(:select).with(nil, [socket], nil, 0).and_return(nil)

        wrapper = Rcon::SocketWrapper.new(socket)

        expect { wrapper.deliver_packet(packet) }.to raise_error(Rcon::Error::SocketWriteTimeoutError)

        server.close
      end
    end
  end

  describe "#ready_to_read?" do
    it "returns an array containing the socket if ready" do
      server = mock_server_response("foo")
      socket = TCPSocket.open("0.0.0.0", 2000)

      wrapper = Rcon::SocketWrapper.new(socket)

      expect(wrapper.ready_to_read?).to eql([[socket], [], []])

      server.close
    end

    it "raises a `Error::SocketReadTimeoutError` if not ready" do
      stub_const("Rcon::SocketWrapper::TIMEOUT", 0)
      server = TCPServer.new("0.0.0.0", 2000)
      socket = TCPSocket.open("0.0.0.0", 2000)
      allow(IO).to receive(:select).with([socket], nil, nil, 0).and_return(nil)

      wrapper = Rcon::SocketWrapper.new(socket)

      expect { wrapper.ready_to_read? }.to raise_error(Rcon::Error::SocketReadTimeoutError)

      server.close
    end
  end

  describe "#ready_to_write?" do
    it "returns an array containing the socket if ready" do
      server = TCPServer.new("0.0.0.0", 2000)
      socket = TCPSocket.open("0.0.0.0", 2000)

      wrapper = Rcon::SocketWrapper.new(socket)

      expect(wrapper.ready_to_write?).to eql([[], [socket], []])

      server.close
    end

    it "raises a `Error::SocketWriteTimeoutError` if not ready" do
      stub_const("Rcon::SocketWrapper::TIMEOUT", 0)
      server = TCPServer.new("0.0.0.0", 2000)
      socket = TCPSocket.open("0.0.0.0", 2000)
      allow(IO).to receive(:select).with(nil, [socket], nil, 0).and_return(nil)

      wrapper = Rcon::SocketWrapper.new(socket)

      expect { wrapper.ready_to_write? }.to raise_error(Rcon::Error::SocketWriteTimeoutError)

      server.close
    end
  end
end
