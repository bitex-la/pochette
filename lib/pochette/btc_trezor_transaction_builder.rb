class Pochette::BtcTrezorTransactionBuilder < Pochette::BaseTrezorTransactionBuilder
  def self.backend
    @backend || Pochette::BtcTransactionBuilder.backend || Pochette.btc_backend
  end

  def self.force_bip143
    false
  end

  def initialize(options)
    super(options)
    build_trezor_inputs
  end

  def build_trezor_inputs
    base_build_trezor_inputs(inputs || []) do |input, hash, address|
      p2sh_segwit_address = address.first.first.in?(%w[2 3])
      native_segwit_address = address.first[0..2].in?(%w[bc1 tb1])
      hash[:script_type] = 'SPENDP2SHWITNESS' if p2sh_segwit_address
      hash[:script_type] = 'SPENDWITNESS' if native_segwit_address
      hash[:amount] = input[3].to_s if p2sh_segwit_address || native_segwit_address
    end
  end
end
