# Pochette

Pochette is a Bitcoin Wallet for developers, or more accurately a tool for building 
"single purpose wallets".

It's used extensively at [Bitex.la](https://bitex.la) from checking and crediting customer
bitcoin deposits to preparing transactions with bip32 paths instead of input addresess,
ready to be signed with a [Trezor Device](https://www.bitcointrezor.com/)

Pochette offers a common interface to full bitcoin nodes like
[Bitcoin Core](https://bitcoin.org/en/download) or [Toshi](http://toshi.io)
and will let you run several instances of each one of them simultaneously
always choosing the most recent node to query.

It also provides a Pochette::TransactionBuilder class which receives a list
of 'source' addresses and a list of recipients as "address/amount" pairs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pochette'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pochette

## The Pochette::TransactionBuilder

The TransactionBuilder builds transactions from a list of source addresses and a list of recipients,
using Pochette.backend to fetch unspent outputs and related transaction data.
Instantiating will perform all the required queries, you'll be left with a
TransactionBuilder object that is either valid? or not, and if valid,
you can query the results via to_hash.

The TransactionBuilder's initializer receives a single options hash with:
  addresses:
    List of addresses in wallet.
    We will be spending their unspent outputs.
  outputs:
    List of pairs [recipient_address, amount]
    This will not be all the final outputs in the transaction,
    as a 'change' output may be added if needed.
  utxo_blacklist:
    List of utxos to ignore, a list of pairs [transaction hash, position]
  change_address:
    Change address to use. Will default to the first source address.
  fee_per_kb:
    Defaults to 10000 satoshis.
  spend_all:
    Wether to spend all available utxos or just select enough to
    cover the given outputs.

TODO: Document as_hash output.

## Building for Trezor with Pochette::TrezorTransactionBuilder

Same as TransactionBuilder but outputs a transaction hash with all the
required data to create and sign a transaction using a BitcoinTrezor.

* Uses BIP32 addresses instead of regular strings.
  Each address is represented as a pair, with the public address string
  and the BIP32 path as a list of integers, for example:
  ['public-address-as-string', [44, 1, 3, 11]]

* Includes associated transaction data for each input being spent,
  ready to be consumed by your Trezor device.

* Outputs are represented as JSON with script_type as expected by Trezor.
  { script_type: 'PAYTOADDRESS',
    address: '1address-as-string',
    amount: amount_in_satoshis }

TODO: Document as_hash output.

## Using a Bitcoin-Core backend.

Pochette will connect to your bitcoin-core node via JSON-RPC, using the
[bitcoin-rpc gem](https://github.com/bitex-la/bitcoin-rpc)

To properly use Pochette you need to be running your bitcoin node with setting the
"-txindex=1" option to get a full transaction index.
[Learn more about -txindex=1](http://bitcoin.stackexchange.com/questions/35707/what-are-pros-and-cons-of-txindex-option)

Also, if you're creating new addresses and want bitcoin-core to track them you'll want to import
them using the bitcoin-rpc gem, like so:

      >>> BitcoinRpc::Client.new('http://user:pass@your_server').importaddress('1PUBLICADDRESS', '', false)

Setting up bitcoin-core as a backend can be done like this:

      >>> Pochette.backend = Pochette::Backends::BitcoinCore.new('http://user:pass@your_server')

## Using a Toshi backend.

Pochette will connect to your Toshi node's postgres database directly.
It's provided as a separate gem as it depends on the pg gem which needs local
postgres extensions to work. You may need to add some extra indexes to your postgres
to speed things up when using Pochette.
[See the gem readme](https://github.com/bitex-la/pochette-toshi) for more info.

## Using the best of many available backends

Pochette provides a higher level Backend Pochette::Backends::Trendy which chooses
between a pool of available backends always using the one at the highest block height,
(but biased towards using the incumbent backend).

This is useful for automatic fallbacks and redundancy, you could also mix Toshi and Bitcoin-Core
backends and use whatever looks more up to date.

      >>> alpha = Pochette::Backends::BitcoinCore.new('http://user:pass@alpha_host')
      >>> beta = Pochette::Backends::BitcoinCore.new('http://user:pass@beta_host')
      >>> Pochette.backend = Pochette::Backends::Trendy.new([alpha, beta])

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/pochette/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
