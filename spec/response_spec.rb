RSpec.describe Rcon::Response do
  describe ".from_packet" do
    context "when the packet is an auth response packet" do
      it "returns an `Rcon::AuthResponse`" do
        packet = Rcon::Packet.new(1, :SERVERDATA_AUTH_RESPONSE, "foo")

        response = Rcon::Response.from_packet(packet)
        
        expect(response).to be_a(Rcon::AuthResponse)
        expect(response.id).to eql(packet.id)
        expect(response.type).to eql(packet.type)
        expect(response.body).to eql(packet.body)
      end
    end

    context "when the packet is a command response value packet" do
      it "returns an `Rcon::CommandResponse`" do
        packet = Rcon::Packet.new(1, :SERVERDATA_RESPONSE_VALUE, "foo")

        response = Rcon::Response.from_packet(packet)
        
        expect(response).to be_a(Rcon::CommandResponse)
        expect(response.id).to eql(packet.id)
        expect(response.type).to eql(packet.type)
        expect(response.body).to eql(packet.body)
      end
    end

    context "when the response type is invalid" do
      it "returns an `Rcon::Error::UnsupportedResponseTypeError" do
        packet = Rcon::Packet.new(1, :BAD, "foo")

        expect { Rcon::Response.from_packet(packet) }.to raise_error(
          an_instance_of(Rcon::Error::UnsupportedResponseTypeError).and having_attributes(
            response_type: :BAD
          )
        )
      end
    end
  end
end

RSpec.describe Rcon::AuthResponse do
  describe "#success?" do
    it "is true when id != -1" do
      expect(Rcon::AuthResponse.new(id: 6, type: :SERVERDATA_AUTH_RESPONSE, body: "").success?).
        to eql(true)
    end

    it "is false when id == -1" do
      expect(Rcon::AuthResponse.new(id: -1, type: :SERVERDATA_AUTH_RESPONSE, body: "").success?).
        to eql(false)
    end
  end
end
