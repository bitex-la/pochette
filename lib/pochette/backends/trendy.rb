# The Trendy backend delegates calls to Toshi or BitcoinCore backends
# to list unspent outputs, incoming payments, etcetera.
# It chooses the backend to use based on its latest block, trying
# to always use the most up to date one.
# Its public instance methods are the contract to be used by any
# other backend, all Pochette backends must define
# thes public methods (Except for the initializer).
class Pochette::Backends::Trendy
  def initialize(backends)
    @backends = backends
  end
  
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
    backend.incoming_for(addresses, min_date)
  end
  
  # Gets the total received, spent and balance for
  # a list of addresses. Confirmed balances are enforced to have a number
  # of confirmation, appearing in a block is not enough.
  # Returns a hash with:
  # { address: [received, sent, total,
  #             unconfirmed_received, unconfirmed_sent, unconfirmed_total],
  #   ...}
  def balances_for(addresses, confirmations)
    backend.balances_for(addresses, confirmations)
  end

  # Get unspent utxos for the given addresses,
  # returns a list of lists like so:
  # [[address, txid, position (vout), amount (in satoshis)], ...]
  def list_unspent(addresses)
    backend.list_unspent(addresses)
  rescue OpenURI::HTTPError => e
    # Blockchain.info returns 500 when there are no unspent outputs
    if e.io.read == "No free outputs to spend"
      return []
    else
      raise
    end
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
    backend.list_transactions(txids)
  end

protected

  # Chooses a backend to use, gives a small advantage to incumbent backend.
  def backend
    return @backend if @backend && @last_choice_on > 10.minutes.ago

    @backend ||= @backends.first

    @last_choice_on = Time.now
    challenger, height = @backends
      .reject{|b| b == @backend }
      .collect{|b| [b, b.block_height] }
      .sort_by(&:last)
      .last

    @backend = height > (@backend.block_height + 1) ? challenger : @backend
  end
end
