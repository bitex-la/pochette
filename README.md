# Pochette

Pochette is a Bitcoin Wallet for developers, or more accurately a tool for building 
"single purpose wallets".

It's used extensively at [Bitex.la](https://bitex.la) from checking and crediting customer
bitcoin deposits to preparing transactions with bip32 paths instead of input addresess,
ready to be signed with a [Trezor Device](https://www.bitcointrezor.com/)

Pochette offers a common interface to full bitcoin nodes like
[Bitcoin Core](https://bitcoin.org/en/download)
[Blockchain.info](https://blockchain.info/api) or [Toshi](http://toshi.io)
and will let you run several instances of each one of them simultaneously
always choosing the most recent node to query. 

It also provides a Pochette::TransactionBuilder class which receives a list
of 'source' addresses and a list of recipients as "address/amount" pairs and
uses them to select unspent outputs and build a raw transaction to be signed
and broadcasted.

The Pochette::TrezorTransactionBuilder class extends Pochette::TransactionBuilder
including transactions, inputs and outputs that are formatted in a way they can
be passed directly to a Trezor device for signing.

## Table of contents
- [Installation and Setup](#installation-and-setup)
- [Pochette::TransactionBuilder](#the-pochettetransactionbuilder)
- [Pochette::TrezorTransactionBuilder](#the-pochettetrezortransactionbuilder)
- [Backend API](#backend-api)
  - [incoming_for(addresses, min_date)](#incoming_foraddresses-min_date)
  - [balances_for(addresses, confirmations)](#balances_foraddresses-confirmations)
  - [list_unspent(addresses)](#list_unspentaddresses)
  - [list_transactions(txids)](#list_transactionstxids)
  - [block_height](#block_height)
  - [pushtx(hex)](#pushtxhex)
- Supported Backends
  - [BitcoinCore Backend](#bitcoincore-backend)
  - [BlockchainInfo Backend](#blockchaininfo-backend)
  - [Toshi Backend](#toshi-backend)
  - [Trendy Backend](#trendy-backend)

## Installation and Setup

Add this line to your application's Gemfile:

```ruby
gem 'pochette'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pochette

You will probably want to setup Pochette with a global default backend,
the backend can also be configured separately for each instance of
a Pochette::TransactionBuilder

```ruby
>>> Pochette.backend = Pochette::Backends::BlockchainInfo.new
>>> Pochette::TransactionBuilder.backend = Pochette::Backends::BlockchainInfo.new
>>> Pochette::TrezorTransactionBuilder.backend = Pochette::Backends::BlockchainInfo.new
```

Pochette can also be configured to use the bitcoin testnet, this will change
the default network used by the Bitcoin gem and may alter the way backends work too.

```ruby
>>> Pochette.testnet = true
```

## The Pochette::TransactionBuilder

The TransactionBuilder builds transactions from a list of source addresses and a list of recipients,
using a configured backend to fetch unspent outputs and related transaction data.
Instantiating will perform all the required queries, you'll be left with a
TransactionBuilder object that is either valid? or not, and if valid,
you can query the results via to_hash.

#### Receives
The TransactionBuilder's initializer receives a single options hash with:

<dl>
<dt>addresses:</dt>
<dd>
  List of addresses in wallet.
  We will be spending their unspent outputs.
</dd>
<dt>outputs:</dt>
<dd>
  List of pairs [recipient_address, amount]
  This will not be all the final outputs in the transaction,
  as a 'change' output may be adted if needed.
</dd>
<dt>utxo_blacklist:</dt>
<dd>
  Optional. List of utxos to ignore, a list of pairs [transaction hash, position]
</dd>
<dt>change_address:</dt>
<dd>
  Optional. Change address to use. Will default to the first source address.
</dd>
<dt>fee_per_kb:</dt>
<dd>
  Optional. Defaults to 10000 satoshis.
</dd>
<dt>spend_all:</dt>
<dd>
  Optional. Boolean. Wether to spend all available utxos or just select enough to
  cover the given outputs.
</dd>
</dl>

#### Returns

A hash with

<dl>
<dt>input_total:</dt>
<dd>The sum of all input amounts, in satoshis.</dd>
<dt>output_total:</dt>
<dd>The sum of all outputs, in satoshis.</dd>
<dt>fee:</dt>
<dd>fee to pay (input_total - output_total).</dd>
<dt>outputs:</dt>
<dd>Array of [destination address, amount in satoshis]</dd>
<dt>inputs:</dt>
<dd>Array of [input address, utxo transaction hash, utxo position, amount]</dd>
<dt>utxos_to_blacklist:</dt>
<dd>
  Transaction inputs formatted to be used as utxo_blacklist on another
  TransactionBuilder.
</dd>
</dl>


```ruby
>>> require 'pochette'
>>> backend = Pochette::Backends::BlockchainInfo.new
>>> transaction = Pochette::TransactionBuilder.new({
      addresses: ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9"],
      outputs: [
        ["mvtUvWSWCU7knrcMVzjcKJgjL1LdekLK5q", 1_0000_0000],
      ],
      utxo_blacklist: [
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1]
      ],
      change_address: 'mgaTEUM4ZE9kLiK58FcffwHfvxpte5CfvE',
      fee_per_kb: 10000,
      spend_all: false,
      backend: backend
    })
>>> transaction.valid?
=> true
>>> transaction.as_hash
=> {
    input_total: 2_0000_0000,
    output_total: 1_9999_0000,
    fee: 10000,
    outputs: [
      ["mvtUvWSWCU7knrcMVzjcKJgjL1LdekLK5q", 1_0000_0000],
      ["mgaTEUM4ZE9kLiK58FcffwHfvxpte5CfvE", 9999_0000],
    ],
    inputs: [
      [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
        "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
        1,
        200000000
      ],
    ],
    utxos_to_blacklist: [
      ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1]
    ],
   }
```

## The Pochette::TrezorTransactionBuilder

Builds a transaction like TransactionBuilder but includes transaction data
and formats inputs and outputs in a way that can be sent directly to your trezor
device.
If you're using [Trezor Connect](https://github.com/trezor/connect) for signing
then you won't need to pass in the transactions.

#### Receives
The TransactionBuilder's initializer receives a single options hash with:

<dl>
<dt>addresses:</dt>
<dd>
  List of addresses in wallet. We will be spending their unspent outputs.
  Each address is represented as a pair, with the public address string
  and the BIP32 path as a list of integers, for example:
  ['public-address-as-string', [44, 1, 3, 11]]
</dd>
<dt>outputs:</dt>
<dd>
  List of pairs [recipient_address, amount]
  This will not be all the final outputs in the transaction,
  as a 'change' output may be adted if needed.
</dd>
<dt>utxo_blacklist:</dt>
<dd>
  Optional. List of utxos to ignore, a list of pairs [transaction hash, position]
</dd>
<dt>change_address:</dt>
<dd>
  Optional. Change address to use. Will default to the first source address.
</dd>
<dt>fee_per_kb:</dt>
<dd>
  Optional. Defaults to 10000 satoshis.
</dd>
<dt>spend_all:</dt>
<dd>
  Optional. Boolean. Wether to spend all available utxos or just select enough to
  cover the given outputs.
</dd>
</dl>

#### Returns

A hash with

<dl>
<dt>input_total:</dt>
<dd>The sum of all input amounts, in satoshis.</dd>
<dt>output_total:</dt>
<dd>The sum of all outputs, in satoshis.</dd>
<dt>fee:</dt>
<dd>fee to pay (input_total - output_total).</dd>
<dt>outputs:</dt>
<dd>Array of [destination address, amount in satoshis]</dd>
<dt>inputs:</dt>
<dd>Array of [input address, utxo transaction hash, utxo position, amount]</dd>
<dt>utxos_to_blacklist:</dt>
<dd>
  Transaction inputs formatted to be used as utxo_blacklist on another
  TransactionBuilder.
</dd>
<dt>transactions:</dt>
<dd>Transaction data for each input.</dd>
<dt>trezor_inputs:</dt>
<dd>
  List of inputs as hashes with bip32 paths instead of addresses
  { address_n: [42,1,1],
    prev_hash: "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
    prev_index: 1}
</dd>
<dt>trezor_outputs:</dt>
<dd>
  List of outputs as Hashes with:
  { script_type: 'PAYTOADDRESS',
    address: '1address-as-string',
    amount: amount in satoshis }
</dd>
</dl>

```ruby
>>> require 'pochette'
>>> backend = Pochette::Backends::BlockchainInfo.new
>>> transaction = Pochette::TransactionBuilder.new({
      addresses: [
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", [44, 1, 3, 11]]
      ],
      outputs: [
        ["mvtUvWSWCU7knrcMVzjcKJgjL1LdekLK5q", 1_0000_0000],
      ],
      utxo_blacklist: [
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1]
      ],
      change_address: 'mgaTEUM4ZE9kLiK58FcffwHfvxpte5CfvE',
      fee_per_kb: 10000,
      spend_all: false
    })
>>> transaction.valid?
=> true
>>> transaction.as_hash
=> {
    input_total: 2_0000_0000,
    output_total: 1_9999_0000,
    fee: 10000,
    outputs: [
      ["mvtUvWSWCU7knrcMVzjcKJgjL1LdekLK5q", 1_0000_0000],
      ["mgaTEUM4ZE9kLiK58FcffwHfvxpte5CfvE", 9999_0000],
    ],
    trezor_outputs: [
      { script_type: 'PAYTOADDRESS',
        address: "mvtUvWSWCU7knrcMVzjcKJgjL1LdekLK5q",
        amount: 1_0000_0000 },
      { script_type: 'PAYTOADDRESS',
        address: "mgaTEUM4ZE9kLiK58FcffwHfvxpte5CfvE",
        amount: 9999_0000 },
    ],
    inputs: [
      [ "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
        "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
        1,
        200000000
      ],
    ],
    trezor_inputs: [
      { address_n: [43,1,3,11],
        prev_hash: "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
        prev_index: 1 },
    ],
    transactions: [
      { hash: "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
        version: "1",
        lock_time: "0",
        inputs: [
          { prev_hash: "158d6bbe586b4e00347f992e8296532d69f902d0ead32d964b6c87d4f8f0d3ea",
            prev_index: 0,
            sequence: 4294967295,
            script_sig: "SCRIPTSCRIPTSCRIPT"
          }
        ],
        bin_outputs: [
          { amount: 1234568, script_pubkey: "76a914988cb8253f4e28be6e8bfded1b4aa11c646e1a8588ac" },
          { amount: 200000000, script_pubkey: "76a914988cb8253f4e28be6e8bfded1b4aa11c646e1a8588ac"}
        ]
      }
    ],
    utxos_to_blacklist: [
      ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1]
    ],
   }
```

## Backend API

Pochette offers a common interface to full bitcoin nodes like
[Bitcoin Core](https://bitcoin.org/en/download)
[Blockchain.info](https://blockchain.info/api) or [Toshi](http://toshi.io)
and will let you run several instances of each one of them simultaneously
always choosing the most recent node to query. 

## incoming_for(addresses, min_date)

The incoming_for method is useful when registering deposits received to
a number of bitcoin addresses.

#### Receives
- addresses: A list of public bitcoin addresses to check for incoming transactions.
- min_date: Do not check for deposits earlier than this date. This is only to prevent
    fetching too many results if the backend was to return too many,
    each backend may apply its own limits so higher value here is not guaranteed to
    fetch more results.

#### Returns
  A list with

- Amount received, in satoshis.
- Address which received the deposit.
- Transaction hash for the deposit.
- Confirmations for the transaction. 
- Position of this deposit in the transaction outputs list.
- Senders, as a comma-separated list of addresses (no whitespaces)

```ruby
>>> require 'pochette'
>>> backend = Pochette::Backends::BlockchainInfo.new
>>> addresses = [
      'mjfa56Keq7PXRKgdPSDB6eWLp4aaAVcj6L', 
      'mwZE4QfzzriE7nsgHSWbgmtT7s6SDysYvP',
      'mvrDG7Ts6Mq9ejhZxdsQLjbScycVaktqsg',
      'mxYzRdJfPk8PcaKSsSzNkX85mMfNcr2CGr',
      'mzbXim4u1Nq4J2kVggu471pZL3ahxNkmE9',
      'mhLAgRz5f1YogfYBZCDFSRt3ceeKBPVEKg',
    ]
>>> Pochette.backend.incoming_for(addresses, 1.day.ago) 
=> [
    [ 500000, "mjfa56Keq7PXRKgdPSDB6eWLp4aaAVcj6L",
      "fb401691795a73e0160252c00af18327a15006fcdf877ccca0c116809669032e", 1629, 0,
      "my2hmDuD9XjmtQWFu9HyyNAsE5WGSDBKpQ"],
    [100000, "mxYzRdJfPk8PcaKSsSzNkX85mMfNcr2CGr",
      "250978b77fe1310d6c72239d9e9589d7ac3dc6edf1b2412806ace5104553da34", 1648, 1,
      "mv9ES7SmQQQ8dpMravBKsLWukgxU2DXfFs"],
    [500000, "mvrDG7Ts6Mq9ejhZxdsQLjbScycVaktqsg",
      "d9afd460b0a5e065fdd87bf97cb1843a29ea588c59daabd1609794e8166bb75f", 1648, 0,
      "my2hmDuD9XjmtQWFu9HyyNAsE5WGSDBKpQ"],
    [ 100000, "mxYzRdJfPk8PcaKSsSzNkX85mMfNcr2CGr",
      "5bd72a4aa7818f47ac8943e3e17519be00c46530760860e608d898d728b9d46e", 553, 1,
      "mvUhgW1ZcUju181bvwEhmZu2x2sRdbV4y2"],
    [ 500000, "mwZE4QfzzriE7nsgHSWbgmtT7s6SDysYvP",
      "b252037526ecb616ab5901552abb903f00bf73400a1fc49b5b5bd699b84bce77", 1632, 0,
      "my2hmDuD9XjmtQWFu9HyyNAsE5WGSDBKpQ"],
    [ 500000, "mzbXim4u1Nq4J2kVggu471pZL3ahxNkmE9",
      "ff768084764a05d1de72628432c0a4419538b2786089ec8ad009f6096bc69fe1", 1660, 0,
      "my2hmDuD9XjmtQWFu9HyyNAsE5WGSDBKpQ"]
   ]
```

## balances_for(addresses, confirmations)

Gets confirmed and unconfirmed sent, received and total balances for the given
addresses. It's useful for payment processing as you can see what's the total
amount seen on the network for a given address, and the final confirmed amount as well.

#### Receives
  - addresses: A list of public bitcoin addresses to check balances for.
  - confirmations: How many confirmations to use for the 'confirmed' amounts.

#### Returns
  A hash where keys are public addresses and values ara a list of
  
  - Confirmed received
  - Confirmed sent
  - Confirmed balance
  - Unconfirmed received
  - Unconfirmed sent
  - Unconfirmed balance

```ruby
>>> require 'pochette'
>>> backend = Pochette::Backends::BlockchainInfo.new
>>> addresses = [
      'mjfa56Keq7PXRKgdPSDB6eWLp4aaAVcj6L', 
      'mwZE4QfzzriE7nsgHSWbgmtT7s6SDysYvP',
      'mvrDG7Ts6Mq9ejhZxdsQLjbScycVaktqsg',
      'mxYzRdJfPk8PcaKSsSzNkX85mMfNcr2CGr',
      'mzbXim4u1Nq4J2kVggu471pZL3ahxNkmE9',
      'mhLAgRz5f1YogfYBZCDFSRt3ceeKBPVEKg',
    ]
>>> backend.balances_for(addresses, 6) 
=> {
    "mhLAgRz5f1YogfYBZCDFSRt3ceeKBPVEKg" =>
      [0.00544426, 0.00544426, 0.0, 0.00544426, 0.00544426, 0.0],
    "mjfa56Keq7PXRKgdPSDB6eWLp4aaAVcj6L" =>
      [0.005, 0.0, 0.005, 0.006, 0.0, 0.006],
    "mvrDG7Ts6Mq9ejhZxdsQLjbScycVaktqsg" =>
      [0.005, 0.0, 0.005, 0.005, 0.0, 0.005],
    "mwZE4QfzzriE7nsgHSWbgmtT7s6SDysYvP" =>
      [0.005, 0.0, 0.005, 0.005, 0.0, 0.005],
    "mxYzRdJfPk8PcaKSsSzNkX85mMfNcr2CGr" =>
      [0.002, 0.0, 0.002, 0.002, 0.0, 0.002],
    "mzbXim4u1Nq4J2kVggu471pZL3ahxNkmE9" =>
      [0.005, 0.0, 0.005, 0.005, 0.0, 0.005],
   }
```

## list_unspent(addresses)

Gets unspent transaction outputs (a.k.a. utxos) for all the given addresses.
You may not need to use this directly, but rather through a
Pochette::TransactionBuilder which is smart about selecting utxos.

#### Receives
  - addresses: A list of public bitcoin addresses to check balances for.

#### Returns
  A list of list, each of them is
  
  - Address
  - Transaction Hash
  - Output position in transaction
  - Unspent amount

```ruby
>>> require 'pochette'
>>> backend = Pochette::Backends::BlockchainInfo.new
>>> addresses = [
      'mjfa56Keq7PXRKgdPSDB6eWLp4aaAVcj6L', 
      'mwZE4QfzzriE7nsgHSWbgmtT7s6SDysYvP',
      'mvrDG7Ts6Mq9ejhZxdsQLjbScycVaktqsg',
      'mxYzRdJfPk8PcaKSsSzNkX85mMfNcr2CGr',
      'mzbXim4u1Nq4J2kVggu471pZL3ahxNkmE9',
      'mhLAgRz5f1YogfYBZCDFSRt3ceeKBPVEKg',
    ]
>>> backend.list_unspent(addresses).should == [
  ["mjfa56Keq7PXRKgdPSDB6eWLp4aaAVcj6L",
  "fb401691795a73e0160252c00af18327a15006fcdf877ccca0c116809669032e", 0, 500000],
  ["mxYzRdJfPk8PcaKSsSzNkX85mMfNcr2CGr",
  "250978b77fe1310d6c72239d9e9589d7ac3dc6edf1b2412806ace5104553da34", 1, 100000],
  ["mvrDG7Ts6Mq9ejhZxdsQLjbScycVaktqsg",
  "d9afd460b0a5e065fdd87bf97cb1843a29ea588c59daabd1609794e8166bb75f", 0, 500000],
  ["mxYzRdJfPk8PcaKSsSzNkX85mMfNcr2CGr",
  "5bd72a4aa7818f47ac8943e3e17519be00c46530760860e608d898d728b9d46e", 1, 100000],
  ["mwZE4QfzzriE7nsgHSWbgmtT7s6SDysYvP",
  "b252037526ecb616ab5901552abb903f00bf73400a1fc49b5b5bd699b84bce77", 0, 500000],
  ["mjfa56Keq7PXRKgdPSDB6eWLp4aaAVcj6L",
  "9142d7a8e96124a36db9708dd21afa4ac81f15a77bd85c06f16e808a4d700da2", 1, 100000],
  ["mzbXim4u1Nq4J2kVggu471pZL3ahxNkmE9",
  "ff768084764a05d1de72628432c0a4419538b2786089ec8ad009f6096bc69fe1", 0, 500000]
]
```

## list_transactions(txids)

List full transaction data for the given transaction hashes. The output 
is formatted for Trezor as required by their multi-step signature process.
You may not want to use this directly and use Pochette::TrezorTransactionBuilder
instead.

#### Receives
  - Transactions: A list of Transaction ids

#### Returns
  A list of ruby hashes will transaction data for each id passed.

```ruby
>>> require 'pochette'
>>> backend = Pochette::Backends::BlockchainInfo.new
>>> transactions = [
      "fb401691795a73e0160252c00af18327a15006fcdf877ccca0c116809669032e",
      "250978b77fe1310d6c72239d9e9589d7ac3dc6edf1b2412806ace5104553da34",
    ]
>>> backend.list_transactions(transactions)
=> [{ hash: "fb401691795a73e0160252c00af18327a15006fcdf877ccca0c116809669032e",
      version: 1,
      lock_time: 0,
      inputs: [
        { prev_hash: "f948600a52719ec63947bd47105411c2cb032bda91b08b25bb7b1de22f1f7458",
          prev_index: 1,
          sequence: 4294967295,
          script_sig: "483045022100898b773c1cf095d5c1608a892673ad067387663e00327e7b88dd48cc4eb9cf2a02203a53336afd4440ea52c6a55e07ac60035dc386cb01b5b6810efac018f0346fad01210316cff587a01a2736d5e12e53551b18d73780b83c3bfb4fcf209c869b11b6415e"
        }
      ],
      bin_outputs: [
        { amount: 500000, script_pubkey: "76a9142d81b210deb7e22475cd7f2fda0bf582dddc9da788ac" },
        { amount: 276607256, script_pubkey: "76a914c01a7ca16b47be50cbdbc60724f701d52d75156688ac"}
      ]
    },
    { hash: "250978b77fe1310d6c72239d9e9589d7ac3dc6edf1b2412806ace5104553da34",
      version: 1,
      lock_time: 0,
      inputs: [
        { prev_hash: "8505c663d0414b678827eed85ba9e7652e616c19ff1be871f6b083d5ed400a20",
          prev_index: 0,
          sequence: 4294967295,
          script_sig: "47304402203ac7cb9afe1a14189b63807aff301ef6bb8507f6dc0471bcee5362282a8c3e38022012c3bfe9680f013735f0d6d012d6420383c0e3a1dbf010f97be9cc834a93d1f601210221af8672ff613d2ea198d8dadcc387a36ef47d7cba6f541221db61b96aa20149"
        }
      ],
      bin_outputs: [
        { amount: 999293000, script_pubkey: "76a91426beab63a5fb7b2103929e91b65f339a2c5b285088ac"},
        { amount: 100000, script_pubkey: "76a914badcbfae4d83a52dc2c8f68605663adc9d4922a688ac"}
      ]
    }
  ]
```

## block_height

Get the latest block height for this backend. Always in the main branch.
  
```ruby
>>> require 'pochette'
>>> backend = Pochette::Backends::BlockchainInfo.new
>>> backend.get_height
=> 376152
```

## pushtx

Propagates a raw transaction to the network.

#### Receives
  - transaction: A raw transaction in hex format

#### Returns
  The transaction id (hash)
  
```ruby
>>> require 'pochette'
>>> hex = "0100000001d11a6cc978fc41aaf5b24fc5c8ddde71fb91ffdba9579cd62ba20fc284b2446c000000008a47304402206d2f98829a9e5017ade2c084a8b821625c35aeaa633f718b1c348906afbe68b00220094cb8ee519adcebe866e655532abab818aa921144bd98a12491481931d2383a014104e318459c24b89c0928cec3c9c7842ae749dcca78673149179af9155c80f3763642989df3ffe34ab205d02e2efd07e9a34db2f00ed8b821dd5bb087ff64df2c9effffffff0280f0fa02000000001976a9149b754a70b9a3dbb64f65db01d164ef51101c18d788ac40aeeb02000000001976a914aadf5d54eda13070d39af72eb5ce40b1d3b8282588ac00000000"
>>> backend = Pochette::Backends::BlockchainInfo.new
>>> backend.pushtx(hex)
=> 'fb92420f73af6d25f5fab93435bc6b8ebfff3a07c02abd053f0923ae296fe380'
```

## BitcoinCore backend

Pochette will connect to your bitcoin-core node via JSON-RPC, using the
[bitcoin-rpc gem](https://github.com/bitex-la/bitcoin-rpc)

To properly use Pochette you need to be running your bitcoin node with setting the
"-txindex=1" option to get a full transaction index.
[Learn more about -txindex=1](http://bitcoin.stackexchange.com/questions/35707/what-are-pros-and-cons-of-txindex-option)

Also, if you're creating new addresses and want bitcoin-core to track them you'll want to import
them using the bitcoin-rpc gem, like so:

```ruby
>>> BitcoinRpc::Client.new('http://user:pass@your_server').importaddress('1PUBLICADDRESS', '', false)
```

Setting up bitcoin-core as a backend can be done like this:

```ruby
>>> Pochette.backend = Pochette::Backends::BitcoinCore.new('http://user:pass@your_server')
```

## BlockchainInfo backend

Pochette can use blockchain.info's public API to fetch unspent outputs,
sleeping a bit after each request to prevent blockchain.info from banning your IP.
This backend is probably the slowest one but also the one that's more convenient for
testing and managing small wallets.

This backend is not usable for testnet transactions, all queries will be done to the
main network.

You can create a blockchain.info backend like this

```ruby
>>> Pochette::Backends::BlockchainInfo.new
```

The default cooldown time is 1 second after each request, but if you have a Blockchain.info
API key you can configure your backend like so:

```ruby
>>> Pochette::Backends::BlockchainInfo.cooldown = 0.1 # Make the cooldown a tenth of a second
>>> Pochette.backend = Pochette::Backends::BlockchainInfo.new("your_api_key")
```

## Toshi backend

Pochette will connect to your Toshi node's postgres database directly.
It's provided as a separate gem as it depends on the pg gem which needs local
postgres extensions to work. You may need to add some extra indexes to your postgres
to speed things up when using Pochette.
[See the gem readme](https://github.com/bitex-la/pochette-toshi) for more info.

## Trendy Backend

Pochette provides a higher level Backend Pochette::Backends::Trendy which chooses
between a pool of available backends always using the one at the highest block height,
(but biased towards using the incumbent backend).

This is useful for automatic fallbacks and redundancy, you could also mix Toshi and Bitcoin-Core
backends and use whatever looks more up to date.

```ruby
>>> alpha = Pochette::Backends::BitcoinCore.new('http://user:pass@alpha_host')
>>> beta = Pochette::Backends::BitcoinCore.new('http://user:pass@beta_host')
>>> Pochette.backend = Pochette::Backends::Trendy.new([alpha, beta])
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/pochette/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
