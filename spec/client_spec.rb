RSpec.describe Rcon::Client do
  include TcpHelper

  describe "#initialize" do
    it "takes in host, port, and password as params and returns an instance of Rcon::Client" do
      expect(Rcon::Client.new(host: "0.0.0.0", port: 25575, password: "foo")).to be_a(Rcon::Client)
    end
  end

  describe "#authenticate!" do
    context "successfully" do
      context "with preceeding response value packet (ignore_first_packet: true)" do
        it "returns an instance of `AuthResponse`" do
          # packet id
          allow(SecureRandom).to receive(:rand).with(1000).and_return(666)
          server = mock_server_auth_response(666)
          client = Rcon::Client.new(host: "0.0.0.0", port: 2000, password: "foo")
          response = client.authenticate!

          expect(response).to be_a(Rcon::AuthResponse)
          expect(response.id).to eql(666)
          expect(response.type).to eql(:SERVERDATA_AUTH_RESPONSE)

          server.close
        end
      end

      context "without preceeding response value packet (ignore_first_packet: false)" do
        it "returns an instance of `AuthResponse`" do
          # packet id
          allow(SecureRandom).to receive(:rand).with(1000).and_return(666)
          server = mock_server_auth_response(666, initial_response_value_packet: false)
          client = Rcon::Client.new(host: "0.0.0.0", port: 2000, password: "foo")
          response = client.authenticate!(ignore_first_packet: false)

          expect(response).to be_a(Rcon::AuthResponse)
          expect(response.id).to eql(666)
          expect(response.type).to eql(:SERVERDATA_AUTH_RESPONSE)

          server.close
        end
      end
    end

    context "unsuccessfully" do
      context "with preceeding response value packet (ignore_first_packet: true)" do
        it "raises an `Rcon::Error::AuthError`" do
          # packet id
          allow(SecureRandom).to receive(:rand).with(1000).and_return(666)
          server = mock_server_auth_response(666, success: false)
          client = Rcon::Client.new(host: "0.0.0.0", port: 2000, password: "foo")

          expect { client.authenticate! }.to raise_error(Rcon::Error::AuthError)

          server.close
        end
      end

      context "without preceeding response value packet (ignore_first_packet: false)" do
        it "raises an `Rcon::Error::AuthError`" do
          # packet id
          allow(SecureRandom).to receive(:rand).with(1000).and_return(666)
          server = mock_server_auth_response(666, success: false, initial_response_value_packet: false)
          client = Rcon::Client.new(host: "0.0.0.0", port: 2000, password: "foo")

          expect { client.authenticate!(ignore_first_packet: false) }.to raise_error(Rcon::Error::AuthError)

          server.close
        end
      end
    end
  end
end
