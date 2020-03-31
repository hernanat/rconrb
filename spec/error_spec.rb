RSpec.describe Rcon::Error::InvalidPacketTypeError do
  describe "#message" do
    it "is a function of the packet type" do
      err = Rcon::Error::InvalidPacketTypeError.new(:foo)

      expect(err.message).to eql("invalid packet_type: foo")
    end
  end
end

RSpec.describe Rcon::Error::InvalidResponsePacketTypeCodeError do
  describe "#message" do
    it "is a function of the type code" do
      err = Rcon::Error::InvalidResponsePacketTypeCodeError.new(666)

      expect(err.message).to eql("invalid response packet type code: 666")
    end
  end
end

RSpec.describe Rcon::Error::UnsupportedResponseTypeError do
  describe "#message" do
    it "is a function of the response code" do
      err = Rcon::Error::UnsupportedResponseTypeError.new(:FOO)

      expect(err.message).to eql("unsupported response type: FOO")
    end
  end
end
