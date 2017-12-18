class Pochette::BtcTrezorTransactionBuilder < Pochette::BaseTrezorTransactionBuilder
  def self.backend
    @backend || Pochette::BtcTransactionBuilder.backend || Pochette.btc_backend
  end
end
