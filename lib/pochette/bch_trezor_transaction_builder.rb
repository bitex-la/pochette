class Pochette::BchTrezorTransactionBuilder < Pochette::BaseTrezorTransactionBuilder
  def self.backend
    @backend || Pochette::BchTransactionBuilder.backend || Pochette.bch_backend
  end

  def self.force_bip143
    true
  end
end
