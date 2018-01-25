class Pochette::BchTransactionBuilder < Pochette::BaseTransactionBuilder
  # We receive cashaddress but internally we represent them as base58,
  # This is only temporary until al bitcoincash nodes are configured to
  # natively use the new format.
  def initialize(options)
    options[:addresses] = options[:addresses].map{|a| to_legacy_if_needed(a) }
    if options[:outputs]
      options[:outputs] = options[:outputs].map do |address, amount|
        [to_legacy_if_needed(address), amount]
      end
    end
    options[:change_address] = to_legacy_if_needed(options[:change_address])
    super(options)
  end

  def to_legacy_if_needed(address)
    return unless address
    address.include?(':') ? Cashaddress.to_legacy(address) : address
  end

  def self.backend
    @backend || Pochette.bch_backend
  end
end
