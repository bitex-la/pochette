# Wraps any backend to translate Cashaddress arguments into base58
# Bitcoin Cash nodes do not use Cashaddress prominently yet.
# This class may become redundant after native Cashaddress support is widespread.
class Pochette::Backends::BitcoinCashWrapper < Pochette::Backends::Base
  attr_accessor :backend
  delegate :pushtx, :block_height, :verify_signatures, :list_transactions, to: :backend

  def initialize(backend)
    self.backend = backend
  end

  def incoming_for(addresses, min_date)
    @backend.incoming_for(to_legacy(addresses), min_date).map do |row|
      [row[0],
       Cashaddress.from_legacy(row[1]),
       row[2],
       row[3],
       row[4],
       row[5].split(',').map{|a| Cashaddress.from_legacy(a) }.join(','),
       row[6]
      ]
    end
  end

  def balances_for(addresses, confirmations)
    @backend.balances_for(to_legacy(addresses), confirmations)
      .map{|k,v| [Cashaddress.from_legacy(k), v]}.to_h
  end

  def list_unspent(addresses)
    @backend.list_unspent(to_legacy(addresses)).map do |address, *rest|
      [Cashaddress.from_legacy(address), *rest]
    end
  end

  private

  def to_legacy(addresses)
    addresses.map{|a| Cashaddress.to_legacy(a) }
  end
end
