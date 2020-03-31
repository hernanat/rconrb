require "rcon/version"
require "rcon/error/error"
require "rcon/client"

# This module is based on the protocol{https://developer.valvesoftware.com/wiki/Source_RCON_Protocol Source RCON Protocol}
# It is to be used for executing remote commands on servers that implement this protocol, or various flavors of it.
#
# The goal was to design something that could be used to work with the default protocol implementation, but also offer
#   the flexibility to work with problem-children implementations such as the one used by Minecraft.
#
module Rcon
end
