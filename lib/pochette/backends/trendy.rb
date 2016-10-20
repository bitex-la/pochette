# The Trendy backend delegates calls to Toshi or BitcoinCore backends
# to list unspent outputs, incoming payments, etcetera.
# It chooses the backend to use based on its latest block, trying
# to always use the most up to date one.
class Pochette::Backends::Trendy < Pochette::Backends::Base
  def initialize(backends)
    @backends = backends
  end

  delegate :incoming_for, :balances_for, :list_unspent, :list_transactions,
    :pushtx, :block_height, :verify_signatures, to: :backend

protected

  # Chooses a backend to use, gives a small advantage to incumbent backend.
  def backend
    return @backend if @backend && @last_choice_on > 10.minutes.ago

    @backend ||= @backends.first

    @last_choice_on = Time.now
    challenger, height = @backends
      .reject{|b| b == @backend }
      .collect{|b| [b, b.block_height] }
      .sort_by(&:last)
      .last

    @backend = height > (@backend.block_height + 1) ? challenger : @backend
  end
end
