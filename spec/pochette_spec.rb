require 'spec_helper'

describe Pochette do
  it 'has a version number' do
    expect(Pochette::VERSION).not_to be nil
  end

  it 'can set backend at the instance, class or global level.' do
    args = {addresses: ['a','b']}
    bip32args = {bip32_addresses: [['a',[1,1]]] }
    Pochette.btc_backend.should be_nil
    Pochette.bch_backend.should be_nil
    Pochette::BtcTransactionBuilder.backend.should be_nil
    Pochette::BtcTransactionBuilder.new(args).backend.should be_nil

    Pochette::BtcTrezorTransactionBuilder.backend.should be_nil
    Pochette::BtcTrezorTransactionBuilder
      .new(bip32args).backend.should be_nil

    Pochette.btc_backend = 1
    Pochette::BtcTransactionBuilder.backend.should == 1
    Pochette::BtcTransactionBuilder.backend = 2
    Pochette::BtcTransactionBuilder.new(args).backend.should == 2
    foo = Pochette::BtcTransactionBuilder.new(addresses: ['a','b'], backend: 3)
    foo.backend.should == 3
    Pochette::BtcTrezorTransactionBuilder.backend.should == 2
    Pochette::BtcTrezorTransactionBuilder.backend = 4
    Pochette::BtcTrezorTransactionBuilder
      .new(bip32args).backend.should == 4
    bar = Pochette::BtcTrezorTransactionBuilder.new(bip32args)
    bar.backend = 5
    Pochette.btc_backend.should == 1
    Pochette::BtcTransactionBuilder.backend.should == 2
    foo.backend.should == 3
    Pochette::BtcTrezorTransactionBuilder.backend.should == 4
    bar.backend.should == 5

    Pochette.bch_backend.should be_nil
    Pochette::BchTransactionBuilder.new(
      {addresses: ['bchtest:qqshf3tvlmrnfg37hacdyvh6283y5hlhhgep80vn0l']}
    ).backend.should be_nil
  end

  it 'Has a testnet setter and getter' do
    Pochette.testnet.should be_falsey
    Bitcoin.network_name.should == :bitcoin
    Pochette.testnet = true
    Pochette.testnet.should be_truthy
    Bitcoin.network_name.should == :testnet3
    Pochette.should be_testnet
    Pochette.testnet = false
    Bitcoin.network_name.should == :bitcoin
  end
end
