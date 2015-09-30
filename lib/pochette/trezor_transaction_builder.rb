# Same as TransactionBuilder but outputs a transaction hash with all the
# required data to create and sign a transaction using a BitcoinTrezor.

class Pochette::TrezorTransactionBuilder < Pochette::TransactionBuilder

  Contract ({
    :bip32_addresses => C::ArrayOf[[String, C::ArrayOf[Integer]]],
    :outputs => C::Maybe[C::ArrayOf[[String, C::Num]]],
    :utxo_blacklist => C::Maybe[C::ArrayOf[[String, Integer]]],
    :change_address => C::Maybe[String],
    :fee_per_kb => C::Maybe[C::Num],
    :spend_all => C::Maybe[C::Bool],
  }) => C::Any
  def initialize(options)
    options = options.dup
    initialize_bip32_addresses(options)
    super(options)
    return unless valid?
    build_trezor_inputs
    build_trezor_outputs
    build_transactions
  end

  Contract C::None => C::Maybe[({
    :input_total => C::Num,
    :output_total => C::Num,
    :fee => C::Num,
    :outputs => C::ArrayOf[[String, C::Num]],
    :inputs => C::ArrayOf[[String, String, Integer, C::Num]],
    :utxos_to_blacklist => C::ArrayOf[[String, Integer]],
    :transactions => C::ArrayOf[Hash],
    :trezor_inputs => C::ArrayOf[{
      address_n: C::ArrayOf[Integer],
      prev_hash: String,
      prev_index: Integer
    }],
    :trezor_outputs => C::ArrayOf[{
      script_type: String,
      address: String,
      amount: C::Num
    }]
  })]
  def as_hash
    return nil unless valid?
    super.merge(
      trezor_inputs: trezor_inputs,
      trezor_outputs: trezor_outputs,
      transactions: transactions)
  end

protected
  attr_accessor :trezor_outputs
  attr_accessor :trezor_inputs
  attr_accessor :transactions
  attr_accessor :bip32_address_lookup

  def initialize_bip32_addresses(options)
    if options[:bip32_addresses].blank?
      self.errors = [:no_bip32_addresses_given]
      return
    end
    options[:addresses] = options[:bip32_addresses].collect(&:first)
    self.bip32_address_lookup = options[:bip32_addresses].reduce({}) do |accum, addr|
      accum[addr.first] = addr.last
      accum
    end
  end

  def build_trezor_inputs
    self.trezor_inputs = inputs.collect do |input|
      { address_n: bip32_address_lookup[input[0]],
        prev_hash: input[1], prev_index: input[2] }
    end
  end

  def build_trezor_outputs
    self.trezor_outputs = outputs.collect do |address, amount|
      type = Bitcoin.address_type(address) == :hash160 ? 'PAYTOADDRESS' : 'PAYTOSCRIPTHASH'
      { script_type: type, address: address, amount: amount }
    end
  end

  def build_transactions
    txids = inputs.collect{|i| i[1] }
    self.transactions = backend.list_transactions(txids)
  end
end
