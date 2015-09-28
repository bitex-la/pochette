# A bitcoin backend that uses blockchain.info to retrieve information.
# See Pochette::Backends::Trendy to learn more about the backend
# interface and contract.
require 'open-uri'

class Pochette::Backends::BlockchainInfo
  cattr_accessor(:cooldown){1}
  attr_accessor :api_key

  def initialize(key = nil)
    self.api_key = key
  end

  def list_unspent(addresses)
    json = get_json("unspent", {active: addresses.join('|'), format: 'json'})
    json['unspent_outputs'].collect do |utxo|
      address = Bitcoin::Script.new(utxo['script'].htb).get_address
      [address, utxo['tx_hash_big_endian'], utxo['tx_output_n'].to_i, utxo['value']]
    end
  end
  
  def balances_for(addresses, confirmations)
    json = get_json("multiaddr", {active: addresses.join('|'), format: 'json'})
    result = {}
    json['addresses'].collect do |a|
      address = a['address']
      sent = get_json("q/getsentbyaddress/#{address}",
        {confirmations: confirmations, format: 'json'})
      received = get_json("q/getreceivedbyaddress/#{address}",
        {confirmations: confirmations, format: 'json'})
      result[address] = [
        sat(received), sat(sent), sat(received - sent),
        sat(a['total_received']), sat(a['total_sent']), sat(a['final_balance'])]
    end
    result
  end

  def sat(x)
    x.to_d / 1_0000_0000
  end
  
  def incoming_for(addresses, min_date)
    return unless latest_block = block_height
    addresses.in_groups_of(50, false).collect do |group|
      incoming_for_helper(group, latest_block)
    end.flatten(1)
  end

  def incoming_for_helper(addresses, latest_block)
    json = get_json("multiaddr", {active: addresses.join('|'), format: 'json'})

    json['txs'].collect do |transaction|
      transaction['out'].collect do |out|
        next unless addresses.include? out['addr']
        confirmations = latest_block - transaction['block_height'].to_i
        senders = transaction['inputs'].collect{ |i| i['prev_out']['addr'] }.join(',')
        [ out['value'].to_d, out['addr'], transaction['hash'], confirmations, out['n'], senders ]
      end.compact
    end.flatten(1)
  end

  def list_transactions(txids)
    return nil if txids.empty?
    txids.collect do |txid|
      tx = get_json("rawtx/#{txid}", {format: 'json'})
      inputs = tx['inputs'].collect do |i|
        prevhash = get_json("rawtx/#{i['prev_out']['tx_index']}", {format: 'json'})['hash']
        { prev_hash: prevhash,
          prev_index: i['prev_out']['n'],
          sequence: i['sequence'],
          script_sig: i['script']
        }
      end

      outputs = tx['out'].collect do |o|
        { amount: o['value'].to_i, script_pubkey: o['script'] }
      end

      { hash: tx['hash'], version: tx['ver'], lock_time: tx['lock_time'],
        inputs: inputs, bin_outputs: outputs}
    end
  end

  def block_height
    get_json("latestblock", {format: 'json'})['height'].to_i
  end

  def pushtx(hex)
    uri = URI.parse("https://blockchain.info/pushtx")
    params = { "tx" => hex }
    params['api_code'] = api_key if api_key
    Net::HTTP.post_form(uri, params)
    Bitcoin::Protocol::Tx.new(hex.htb).hash
  end

  def get_json(path, params={})
    params['api_code'] = api_key if api_key
    query = params.empty? ? '' : "?#{params.to_query}"
    retries = 30
    begin
      raw_response = open("https://blockchain.info/#{path}#{query}").read
      sleep cooldown
      Oj.load(raw_response)
    rescue OpenURI::HTTPError => e
      raise if retries < 0 || e.message.to_i != 429
      retries -= 1
      sleep (cooldown * 5)
      retry
    end
  end
end
