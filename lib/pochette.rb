require "pochette/version"
require "bitcoin_rpc"
require "active_support"
require "active_support/core_ext"
require "bitcoin"

module Pochette
  mattr_accessor :backend

  module Backends
  end
end

require "pochette/backends/bitcoin_core"
require "pochette/backends/trendy"
require "pochette/transaction_builder"
require "pochette/trezor_transaction_builder"
