require "pochette/version"
require "bitcoin_rpc"
require "active_support"
require "active_support/core_ext"
require "bitcoin"
require "money-tree"
require "contracts"
require "cashaddress"
C = Contracts

module Pochette
  include Contracts::Core

  mattr_accessor :btc_backend
  mattr_accessor :bch_backend
  
  Contract C::Bool => C::Bool
  def self.testnet=(v)
    Bitcoin.network = v ? :testnet3 : :bitcoin
    @testnet = v
  end

  Contract C::None => C::Bool
  def self.testnet
    @testnet || false
  end

  Contract C::None => C::Bool
  def self.testnet?
    self.testnet
  end

  module Backends
  end

  class InvalidSignatureError < StandardError
  end
end

require "pochette/backends/base"
require "pochette/backends/bitcoin_core"
require "pochette/backends/blockchain_info"
require "pochette/backends/bitcoin_cash_wrapper"
require "pochette/backends/trendy"
require "pochette/backends/bitcore"
require "pochette/base_transaction_builder"
require "pochette/btc_transaction_builder"
require "pochette/bch_transaction_builder"
require "pochette/base_trezor_transaction_builder"
require "pochette/btc_trezor_transaction_builder"
require "pochette/bch_trezor_transaction_builder"
