class Pochette::BchTrezorTransactionBuilder < Pochette::BaseTrezorTransactionBuilder
  def self.backend
    @backend || Pochette::BchTransactionBuilder.backend || Pochette.bch_backend
  end

  def self.force_bip143
    true
  end

  def initialize(options)
    super(options)
    build_trezor_inputs
  end

  def build_trezor_inputs
    base_build_trezor_inputs(inputs || []) { |input, hash, _| hash[:amount] = input[3].to_s }
  end
end
