require 'spec_helper'

describe Pochette do
  it 'has a version number' do
    expect(Pochette::VERSION).not_to be nil
  end

  it 'can set backend at the instance, class or global level.' do
    args = {addresses: ['a','b']}
    Pochette.backend.should be_nil
    Pochette::TransactionBuilder.backend.should be_nil
    Pochette::TransactionBuilder.new(args).backend.should be_nil
    Pochette::TrezorTransactionBuilder.backend.should be_nil
    Pochette::TrezorTransactionBuilder.new(args).backend.should be_nil
    Pochette.backend = 1
    Pochette::TransactionBuilder.backend.should == 1
    Pochette::TransactionBuilder.backend = 2
    Pochette::TransactionBuilder.new(args).backend.should == 2
    foo = Pochette::TransactionBuilder.new(addresses: ['a','b'], backend: 3)
    foo.backend.should == 3
    Pochette::TrezorTransactionBuilder.backend.should == 2
    Pochette::TrezorTransactionBuilder.backend = 4
    Pochette::TrezorTransactionBuilder.new(args).backend.should == 4
    bar = Pochette::TrezorTransactionBuilder.new(args)
    bar.backend = 5
    Pochette.backend.should == 1
    Pochette::TransactionBuilder.backend.should == 2
    foo.backend.should == 3
    Pochette::TrezorTransactionBuilder.backend.should == 4
    bar.backend.should == 5
  end

  it 'Has a testnet setter and getter' do
    Pochette.testnet.should be_falsey
    Bitcoin.network_name.should == :bitcoin
    Pochette.testnet = true
    Pochette.testnet.should be_truthy
    Bitcoin.network_name.should == :testnet
    Pochette.should be_testnet
    Pochette.testnet = false
    Bitcoin.network_name.should == :bitcoin
  end
end
