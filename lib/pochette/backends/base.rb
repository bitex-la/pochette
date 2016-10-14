# All Pochette backends must conform to this interface.
class Pochette::Backends::Base
  # Lists all bitcoins received by a list of addresses
  # after a given date. Includes both confirmed and unconfirmed
  # transactions, unconfirmed transactions have a nil block height.
  # Returns a list of lists as following:
  #   amount: Amount received (in satoshis)
  #   address: Public address receiving the amount.
  #   txid: The hash for the transaction that received it.
  #   confirmations: Transaction confirmations
  #   output position: To disambiguate in case address received more than once.
  #   sender addresses: Comma separated list of input addresses,
  #     used to identify deposits from trusted parties.
  #     can be used to identify deposits from trusted parties.
  def incoming_for(addresses, min_date)
    raise NotImplementedError
  end

  # Gets the total received, spent and balance for
  # a list of addresses. Confirmed balances are enforced to have a number
  # of confirmation, appearing in a block is not enough.
  # Returns a hash with:
  # { address: [received, sent, total,
  #             unconfirmed_received, unconfirmed_sent, unconfirmed_total],
  #   ...}
  def balances_for(addresses, confirmations)
    raise NotImplementedError
  end

  # Get unspent utxos for the given addresses,
  # returns a list of lists like so:
  # [[address, txid, position (vout), amount (in satoshis)], ...]
  def list_unspent(addresses)
    raise NotImplementedError
  end

  # Gets information for the given transactions
  # returns a list of objects, like so:
  # [
  #   { hash: txid,
  #     version: 1,
  #     lock_time: 0,
  #     inputs: [
  #       { prev_hash: txid,
  #         prev_index: 0,
  #         sequence: 0,
  #         script_sig: hex_signature
  #       },
  #       ...
  #     ],
  #     bin_outputs: [
  #       { amount: amount (as satoshis),
  #         script_pubkey: hex_script
  #       },
  #       ...
  #     ]
  #   }
  def list_transactions(txids)
    raise NotImplementedError
  end

  def pushtx(hex, options = { })
    verify_signatures(hex, options) if options[:verify_signatures]
    _pushtx(hex)
    Bitcoin::Protocol::Tx.new(hex.htb).hash
  end

  def _pushtx(hex)
    raise NotImplementedError
  end

  def block_height
    raise NotImplementedError
  end

  def verify_signatures(hex, options = { })
    Bitcoin::P::Tx.new(serialized.htb)
    tx.inputs.each_with_index do |input, idx|
      prev_tx = list_transactions([ input.previous_output ]).first
      outputs = prev_tx[:bin_outputs]
      script_pubkey = outputs[input.prev_out_index][:script_pubkey].htb
      unless tx.verify_input_signature(idx, script_pubkey, Time.now.to_i, options)
        raise "Signature for input #{idx} is invalid."
      end
    end
  end
end
