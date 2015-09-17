require 'spec_helper'

describe Pochette::Backends::Trendy do
  let(:one){ double(block_height: 1) }
  let(:two){ double(block_height: 2) }
  let(:trendy){ Pochette::Backends::Trendy.new([one, two]) }

  it 'chooses the backend which is most up to date' do
    two.should_receive(:incoming_for)
    trendy.incoming_for(['address'], 1.day.ago)
  end

  it 'caches selection for 10 minutes' do
    two.should_receive(:incoming_for).twice
    trendy.incoming_for(['address'], 1.day.ago)
    # Then backend one takes the lead but goes unnoticed
    one.stub(block_height: 4)
    two.stub(block_height: 2)
    trendy.incoming_for(['address'], 1.day.ago)

    # And a few minutes later trendy picks up the change
    Timecop.travel 11.minutes.from_now
    one.should_receive(:incoming_for).once
    trendy.incoming_for(['address'], 1.day.ago)
  end

  it 'favors the incumbent backend if only one block behind' do
    two.should_receive(:incoming_for).twice
    trendy.incoming_for(['address'], 1.day.ago)
    # Then backend one takes the lead but for just one block
    one.stub(block_height: 3)
    two.stub(block_height: 2)
    Timecop.travel 11.minutes.from_now
    trendy.incoming_for(['address'], 1.day.ago)
  end

  it 'has incoming' do
    two.should_receive(:incoming_for)
    trendy.incoming_for(['foo'], 1.day.ago)
  end

  it 'has balances' do
    two.should_receive(:balances_for)
    trendy.balances_for(['foo'], 3)
  end

  it 'lists unspent' do
    two.should_receive(:list_unspent)
    trendy.list_unspent(['foo'])
  end

  it 'lists transactions' do
    two.should_receive(:list_transactions)
    trendy.list_transactions(['foo'])
  end
end

