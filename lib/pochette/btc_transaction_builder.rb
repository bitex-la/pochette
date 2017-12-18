class Pochette::BtcTransactionBuilder < Pochette::BaseTransactionBuilder
  def self.backend
    @backend || Pochette.btc_backend
  end
end
