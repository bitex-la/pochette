# A bitcoin backend that uses bitcoin-core to retrieve information.
# See Pochette::Backends::Trendy to learn more about the backend
# interface and contract.
class Pochette::Backends::BitcoinCore < Pochette::Backends::Base
  def initialize(rpc_url)
    @rpc_url = rpc_url
  end

  def client
    BitcoinRpc::Client.new(@rpc_url)
  end
  
  def incoming_for(addresses, min_date)
    return [] if addresses.empty?

    addresses = addresses.to_set
    from_block = block_height - ((Time.now - min_date) / 60 / 60 * 6).ceil
    block_hash = client.getblockhash(from_block)
    
    result = []
    client.listsinceblock(block_hash, 1, true)[:transactions].each do |t|
      next if t.has_key?(:trusted) && !t[:trusted]
      next unless t[:category] == 'receive'
      next unless addresses.include?(t[:address])
      senders = []
      client.getrawtransaction(t[:txid], 1)[:vin].each do |i|
        raw_sender = client.getrawtransaction(i[:txid], 1)
        senders += raw_sender[:vout][i[:vout]][:scriptPubKey][:addresses]
      end
      result << [(t[:amount] * 1_0000_0000).to_i, t[:address], t[:txid],
        t[:confirmations], t[:vout], senders.join(',')]
    end
    result
  end

  def balances_for(addresses, confirmations)
    return {} if addresses.empty?
    result = addresses.reduce({}) do |accum, address|
      accum[address] = [0,0,0,0,0,0]
      accum
    end
    
    # Populate confirmed received
    client.listreceivedbyaddress(confirmations, false, true).each do |a|
      next unless result[a[:address]]
      result[a[:address]][0] = a[:amount]
      result[a[:address]][1] = a[:amount] # Will substract UTXO from it later.
    end

    # Populate unconfirmed received
    client.listreceivedbyaddress(0, false, true).each do |a|
      next unless result[a[:address]]
      result[a[:address]][3] = a[:amount]
      result[a[:address]][4] = a[:amount] # Will substract UTXO from it later.
    end
    
    # Fix sent amounts to not include amounts which werent actually sent.
    client.listunspent(0, 99999999, addresses).each do |utxo|
      if utxo[:confirmations] >= confirmations
        result[utxo[:address]][1] -= utxo[:amount]
      end
      result[utxo[:address]][4] -= utxo[:amount]
    end
    
    # Totals are just one substraction away
    result.each do |k, v| 
      v[2] = v[0] - v[1]
      v[5] = v[3] - v[4]
    end

    result
  end
  
  def list_unspent(addresses)
    return nil if addresses.empty?
    client.listunspent(1, 99999999, addresses).collect do |u| 
      [u[:address], u[:txid], u[:vout], (u[:amount] * 1_0000_0000).to_i, u[:scriptPubKey]]
    end
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
        { amount: (o[:value] * 1_0000_0000).to_i, script_pubkey: o[:scriptPubKey][:hex] }
      end

      { hash: tx[:txid], version: tx[:version], lock_time: tx[:locktime],
        inputs: inputs, bin_outputs: outputs}
    end
  end

  def block_height
    client.getblockcount
  end

  def propagate(hex)
    client.sendrawtransaction(hex)
  end
end
