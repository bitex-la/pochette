# Same as TransactionBuilder but outputs a transaction hash with all the
# required data to create and sign a transaction using a BitcoinTrezor.
# * Uses BIP32 addresses instead of regular strings.
#   Each address is represented as a pair, with the public address string
#   and the BIP32 path as a list of integers, for example:
#   ['public-address-as-string', [44, 1, 3, 11]]
#
# * Includes associated transaction data for each input being spent,
#   ready to be consumed by your Trezor device.
#
# * Outputs are represented as JSON with script_type as expected by Trezor.
#   { script_type: 'PAYTOADDRESS',
#     address: '1address-as-string',
#     amount: amount_in_satoshis }
#
# Options:
#   bip32_addresses:
#     List of [address, path] pairs in wallet.
#     We will be spending their unspent outputs.
#   outputs:
#     List of pairs [recipient_address, amount]
#     This will not be all the final outputs in the transaction,
#     as a 'change' output may be added if needed.
#   utxo_blacklist:
#     List of utxos to ignore, a list of pairs [transaction hash, position]
#   change_address:
#     Change address to use. Will default to the first source address.
#   fee_per_kb:
#     Defaults to 10000 satoshis.
#   spend_all:
#     Wether to spend all available utxos or just select enough to
#     cover the given outputs.

class Pochette::TrezorTransactionBuilder < Pochette::TransactionBuilder
  def initialize(options)
    options = options.dup
    initialize_bip32_addresses(options)
    super(options)
    return unless valid?
    build_trezor_inputs
    build_trezor_outputs
    build_transactions
  end

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
    self.transactions = Pochette.backend.list_transactions(txids)
  end
end
