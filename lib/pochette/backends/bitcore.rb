# A bitcoin backend that uses Bitcore's Bitcoin Core fork to retrieve information.
# See Pochette::Backends::Base to learn more about the backend
# interface and contract.
class Pochette::Backends::Bitcore < Pochette::Backends::Base
  def initialize(rpc_url)
    @rpc_url = rpc_url
  end

  def client
    BitcoinRpc::Client.new(@rpc_url)
  end
 
  def incoming_for(addresses, min_date)
    return [ ] if addresses.empty?

    addresses = addresses.to_set
    max_height = client.getblockcount
    min_height = max_height - ((Time.now - min_date) / 60 / 60 * 6).ceil

    confirmed = client.getaddressdeltas(addresses: addresses, start: min_height,
                                        end: max_height).collect do |delta|
      build_incoming(delta, max_height - delta[:height] + 1)
    end.compact

    unconfirmed = client.getaddressmempool(addresses: addresses).collect do |tx|
      build_incoming(tx, 0)
    end.compact

    confirmed + unconfirmed
  end

  def build_incoming(tx, confirmations)
    return if tx[:satoshis] < 0
    rawtx = client.getrawtransaction(tx[:txid], 1)
    senders = rawtx[:vin].collect{|i| i[:address] }
    [ tx[:satoshis], tx[:address], tx[:txid],
      confirmations, tx[:index], senders.join(','), rawtx[:height] ]
  end

  def balances_for(addresses, confirmations)
    return { } if addresses.empty?
    result = addresses.reduce({ }) do |accum, address|
      accum[address] = [ 0, 0, 0, 0, 0, 0 ]
      accum
    end

    max_height = block_height - confirmations + 1

    client.getaddressdeltas(addresses: addresses).each do |delta|
      balances = result[delta[:address]]
      amount = delta[:satoshis].to_d / 1_0000_0000
      confirmed = delta[:height] <= max_height

      if amount > 0
        balances[0] += amount if confirmed
        balances[3] += amount
      else
        balances[1] -= amount if confirmed
        balances[4] -= amount
      end
    end

    client.getaddressmempool(addresses: addresses).each do |tx|
      balances = result[tx[:address]]
      amount = tx[:satoshis].to_d / 1_0000_0000
      if amount > 0
        balances[3] += amount
      else
        balances[4] -= amount
      end
    end
 
    # Totals are just one substraction away
    result.each do |k, v| 
      v[2] = v[0] - v[1]
      v[5] = v[3] - v[4]
    end
  end

  def list_unspent(addresses)
    return nil if addresses.empty?
    utxos = [ ]
    addresses.in_groups_of(5000, false).each do |addrs|
      spent_utxos = client.getaddressmempool(addresses: addrs).collect do |tx|
        next unless tx[:prevtxid]
        [ tx[:prevtxid], tx[:prevout] ]
      end.compact

      utxos.concat(client.getaddressutxos(addresses: addrs).collect do |u|
        utxo = [ u[:txid], u[:outputIndex] ]
        next if spent_utxos.include?(utxo)
        [ u[:address], *utxo, u[:satoshis], u[:script] ]
      end.compact)
    end
    utxos
  end

  def list_transactions(txids)
    return nil if txids.empty?
    txids.collect do |txid|
      tx = client.getrawtransaction(txid, 1)
      inputs = tx[:vin].collect do |i|
        { prev_hash: i[:txid],
          prev_index: i[:vout],
          sequence: i[:sequence],
          script_sig: i[:scriptSig][:hex] 
        }
      end

      outputs = tx[:vout].collect do |o|
        { amount: o[:valueSat], script_pubkey: o[:scriptPubKey][:hex] }
      end

      { hash: tx[:txid], version: tx[:version], lock_time: tx[:locktime],
        inputs: inputs, bin_outputs: outputs }
    end
  end

  def block_height
    client.getblockcount
  end

  def propagate(hex)
    client.sendrawtransaction(hex)
  end
end
