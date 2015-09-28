require "pochette/version"
require "bitcoin_rpc"
require "active_support"
require "active_support/core_ext"
require "bitcoin"

module Pochette
  mattr_accessor :backend
  
  def self.testnet=(v)
    @testnet = v
    Bitcoin.network = v ? :testnet : :bitcoin
  end
  def self.testnet
    @testnet
  end
  def self.testnet?
    self.testnet
  end

  module Backends
  end
end

require "pochette/backends/bitcoin_core"
require "pochette/backends/blockchain_info"
require "pochette/backends/trendy"
require "pochette/transaction_builder"
require "pochette/trezor_transaction_builder"
