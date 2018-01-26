class Pochette::BchTransactionBuilder < Pochette::BaseTransactionBuilder
  def self.backend
    @backend || Pochette.bch_backend
  end
end
