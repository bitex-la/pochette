# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pochette/version'

Gem::Specification.new do |spec|
  spec.name          = "pochette"
  spec.version       = Pochette::VERSION
  spec.authors       = ["Nubis", "Eromirou"]
  spec.email         = ["nb@bitex.la", "tr@bitex.la"]

  spec.summary       = %q{Pochette is a Bitcoin Wallet for developers}
  spec.description   = %q{Pochette is a Bitcoin Wallet backend offering a common
    interface to several bitcoin nodes so you can build single purpose wallets.
    You can pass in a bunch of addresses and outputs and it will select the
    appropriate unspent outputs for each of them, calculate change, fees, etc.
    }
  spec.homepage      = "http://github.com/bitex-la/pochette"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]
  spec.add_dependency "activesupport", "~> 4.2"
  spec.add_dependency "bitcoin_rpc", "~> 0.1"
  spec.add_dependency "bitcoin-ruby", "~> 0.0.13"
  spec.add_dependency "money-tree", "~> 0.9"
  spec.add_dependency "contracts", "~> 0.12.0"
  spec.add_dependency "cashaddress", "~> 0.1.0"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "webmock", "~> 1.24"
  spec.add_development_dependency "timecop", "~> 0.8.0"
  spec.add_development_dependency "byebug", "~> 9.0"
end
