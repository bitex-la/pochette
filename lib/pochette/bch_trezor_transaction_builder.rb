class Pochette::BchTrezorTransactionBuilder < Pochette::BaseTrezorTransactionBuilder
  def self.backend
    @backend || Pochette::BchTransactionBuilder.backend || Pochette.bch_backend
  end
end
