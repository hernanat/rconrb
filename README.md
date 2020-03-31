# Rcon

[![hernanat](https://circleci.com/gh/hernanat/rconrb/tree/master.svg?style=svg)](https://circleci.com/gh/hernanat/rconrb/tree/master)
[![Gem Version](https://badge.fury.io/rb/rconrb.svg)](https://badge.fury.io/rb/rconrb)

[The Source RCON Protocol](https://developer.valvesoftware.com/wiki/Source_RCON_Protocol) is a protocol
  designed to allow for the remote execution of commands on a server that supports it.

It is used for many different game servers running on the [Source Dedicated Server](https://developer.valvesoftware.com/wiki/Source_Dedicated_Server), but other
  types of game servers (Minecraft) support it (or flavors of it) as well.

This gem intends to provide a means of executing remote commands via the "vanilla" RCON protocol by default,
  but also offers some configuration options to allow you to work with the more problematic implementations
  of the protocol (i.e. Minecraft).

See the docs for more information

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rconrb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rconrb

## Usage

### Basic Usage

#### Vanilla

```ruby
client = Rcon::Client.new(host: "1.2.3.4", port: 25575, password: "foreveryepsilonbiggerthanzero")
client.authenticate!
client.execute("list")
```

#### Minecraft

Minecraft implements the protocol in such a way that makes me want to tear my hair out. Anyways:

```ruby
client = Rcon::Client.new(host: "1.2.3.4", port: 25575, password: "foreveryepsilonbiggerthanzero")
client.authenticate!(ignore_first_packet: false) # Minecraft RCON does not send a preliminary auth packet
client.execute("list")
```

### Segmented Responses

Some responses are too large to send back in one packet, and so they are broken up across several.
We handle this by sending a "trash" packet along immediately following our initial packet. Since
SRCDS guarantees that packets will be processed in order, and responded to in order, so we basically
we build the response body across several packets until we encounter the trash packet id, in which
case we know that we are finished. It's worth noting that I'm not positive that Minecraft follows
this behavioral guarantee, but throughout the testing that I've done it has seemed to.

Note that the segmented response workflow is disabled by default since most commands won't result
in a segmented response.

#### Vanilla

```ruby
client = Rcon::Client.new(host: "1.2.3.4", port: 25575, password: "foreveryepsilonbiggerthanzero")
client.authenticate!
client.execute("cvarlist", expect_segmented_response: true)
```

#### Minecraft

Minecraft RCON doesn't handle receiving multiple packets in quick succession very well, and seems
to get confused and just close the TCP connection. This has been a long standing issue. The solution
is basically to wait a brief period between the initial packet and the trash packet to give the
server some time to process. This isn't an exact science unfortunately.

```ruby
client = Rcon::Client.new(host: "1.2.3.4", port: 25575, password: "foreveryepsilonbiggerthanzero")
client.authenticate!(ignore_first_packet: false) # Minecraft RCON does not send a preliminary auth packet
client.execute("banlist", expect_segmented_response: true, wait: 0.25)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hernanat/rconrb

TODO: contribution guidelines

