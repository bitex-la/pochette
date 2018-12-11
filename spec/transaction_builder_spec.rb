require 'spec_helper'

describe Pochette::BtcTransactionBuilder do
  before(:each) do
    Pochette::BtcTransactionBuilder.backend = double(
      list_unspent: list_unspent_mock,
      list_transactions: list_transactions_mock
    )
  end
  after(:each){ 
    Pochette::BtcTransactionBuilder.backend = nil 
    Pochette::BchTransactionBuilder.backend = nil 
  }

  it 'does not get confused between bch and btc backends' do
    # This spec is here to make absolutely sure there's no
    # way in hell we can cause a race condition between bch/btc backends
    # when using these class attributes.
    Pochette::BtcTransactionBuilder.backend = double(foo: :btc)

    Pochette::BtcTransactionBuilder.backend.foo.should == :btc
    Pochette::BchTransactionBuilder.backend.should be_nil 

    Pochette::BchTransactionBuilder.backend = double(foo: :bch)

    Pochette::BtcTransactionBuilder.backend.foo.should == :btc
    Pochette::BchTransactionBuilder.backend.foo.should == :bch
  end

  it 'selects one output greater than the required amount' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 1_0000_0000]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses, outputs: outputs)
    transaction.should be_valid
    transaction.as_hash.should == {
      input_total: 2_0000_0000,
      output_total: 1_9999_0000,
      fee: 10000,
      outputs: [
        ["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 1_0000_0000],
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 9999_0000],
      ],
      inputs: [["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
        "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
        1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"]
      ],
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
      ],
    }
  end

  it 'selects more outputs to match the required amount' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 3_0000_0000]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses, outputs: outputs)
    transaction.should be_valid
    transaction.as_hash.should == {
      input_total: 4_0000_0000,
      output_total: 3_9999_0000,
      fee: 10000,
      outputs: [
        ["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 3_0000_0000],
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 9999_0000],
      ],
      inputs: [
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"]
      ],
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1]
      ],
    }
  end

  it 'sends change to change address instead of first sender when specified' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 3_0000_0000]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses,
       outputs: outputs, change_address: '1CHANGEIT')
    transaction.should be_valid
    transaction.as_hash[:outputs].last.first.should == '1CHANGEIT'
  end

  it 'uses up all utxos when spend_all is instructed' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 1_0000_0000]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses,
       outputs: outputs, spend_all: true)
    transaction.should be_valid
    transaction.as_hash.should == {
      input_total: 6_0000_0000,
      output_total: 5_9999_0000,
      fee: 10000,
      inputs: [
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"]
      ],
      outputs: [
        ["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 100000000],
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 499990000]
      ],
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1],
        ["1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 1],
      ]
    }
  end

  it 'selects another utxo just to pay for fees' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 2_0000_0000]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses, outputs: outputs)
    transaction.should be_valid
    transaction.as_hash.should == {
      input_total: 4_0000_0000,
      output_total: 3_9999_0000,
      fee: 10000,
      inputs: [
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
      ],
      outputs: [
        ["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 200000000],
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 199990000]
      ],
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1]
      ]
    }
  end

  it 'can set a higher fee per kb' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 3_0000_0000]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses,
      outputs: outputs, fee_per_kb: 100000)
    transaction.should be_valid
    transaction.as_hash.should == {
      input_total: 4_0000_0000,
      output_total: 3_9996_2200,
      fee: 37800,
      inputs: [
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          1, 2_0000_0000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72",
          1, 2_0000_0000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
      ],
      outputs: [
        ["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 300000000],
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",  99962200]
      ],
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1]
      ]
    }
  end

  it 'can blacklist utxos' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 3_0000_0000]]
    blacklist = [["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses,
       outputs: outputs, utxo_blacklist: blacklist).as_hash
    transaction.should == {
      input_total: 4_0000_0000,
      output_total: 3_9999_0000,
      fee: 10000,
      inputs: [
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"]
      ],
      outputs: [
        ["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 300000000],
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",  99990000]
      ],
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
        ["1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 1],
      ],
    }
  end

  it 'fails if no addresses are given' do
    expect do
      Pochette::BtcTransactionBuilder.new({})
    end.to raise_exception ParamContractError
  end

  it 'fails if minimum output size is not met' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 500]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses, outputs: outputs)
    transaction.should_not be_valid
    transaction.errors.should == [:dust_in_outputs]
    transaction.as_hash.should be_nil
  end

  it 'fails if not enough money for outputs' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 7_0000_0000]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses, outputs: outputs)
    transaction.should_not be_valid
    transaction.errors.should == [:insufficient_funds]
    transaction.as_hash.should be_nil
  end

  it 'fails if not enough money for outputs' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 6_0000_0000]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses, outputs: outputs)
    transaction.should_not be_valid
    transaction.errors.should == [:insufficient_funds]
    transaction.as_hash.should be_nil
  end

  it 'includes a higher fee if change was too small' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 3_9998_9600]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses, outputs: outputs)
    transaction.as_hash.should == {
      input_total: 400000000,
      output_total: 399989600,
      fee: 10400,
      inputs: [
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72",
          1, 200000000, "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"]
      ],
      outputs: [
        ["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 399989600],
      ],
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1],
      ],
    }
  end

  it 'fails if no outputs were given and not spending all' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 3_9998_9600]]
    transaction = Pochette::BtcTransactionBuilder.new(addresses: addresses)
    transaction.should_not be_valid
    transaction.errors.should == [:try_with_spend_all]
  end

  it 'uses supplied inputs' do
    addresses = ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"]
    outputs = [["2BLEscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 3_9998_9600]]
    transaction = Pochette::BtcTransactionBuilder.new(
      inputs: list_unspent_mock,
      addresses: addresses,
      outputs: outputs
    )
    expect(transaction).to be_valid
    expect(Pochette::BtcTransactionBuilder.backend).not_to have_received :list_unspent
  end
end

