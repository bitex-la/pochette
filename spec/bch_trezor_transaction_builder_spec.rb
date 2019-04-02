require 'spec_helper'

describe Pochette::BchTransactionBuilder do
  before(:each) do
    Pochette.testnet = true
    Pochette::BchTrezorTransactionBuilder.backend = 
      Pochette::Backends::BitcoinCashWrapper.new(double(
      list_unspent: (list_unspent_mock + list_unspent_multisig_mock),
      list_transactions: (list_transactions_mock + list_transactions_multisig_mock)
    ))
  end

  after(:each){
    Pochette.btc_backend = nil
    Pochette.bch_backend = nil
    Pochette.testnet = false
  }

  it 'receives bip32 addresses and formats output for trezor' do
    xpub1 = 'xpub661MyMwAqRbcGCmcnz4JtnieVyuvgQFGqZqw3KS1g9khndpF3segkAYbYCKKaQ9Di2ZuWLaZU4Axt7TrKq41aVYx8XTbDbQFzhhDMntKLU5'
    xpub2 = 'xpub661MyMwAqRbcFwc3Nmz8WmMU9okGmeVSmuprwNHCVsfhy6vMyg6g79octqwNftK4g62TMWmb7UtVpnAWnANzqwtKrCDFe2UaDCv1HoErssE'
    xpub3 = 'xpub661MyMwAqRbcGkqPSKVkwTMtFZzEpbWXjM4t1Dv1XQbfMxtyLRGupWkp3fcSCDtp6nd1AUrRtq8tnFGTYgkY1pB9muwzaBDnJSMo2rVENhz'
    addresses = [
      ['bchtest:qp82lfltxpfjmr02aqx93kmwe6a32qtkucp4e2cgyd', [41, 1, 1]],
      ['bchtest:pza05cp9mshq7xx5h8e95cwsgv9lv0dhgyux7cru05', [42, 1, 1]],
      [[xpub1, xpub2, xpub3], [42, 1, 1], 2]
    ]
    outputs = [["bchtest:qpaps04mxmjkv4xmhua7hmmww4999wlcl5sewjt0m0", 7_5000_0000]]
    transaction = Pochette::BchTrezorTransactionBuilder
      .new(bip32_addresses: addresses, outputs: outputs)
    transaction.should be_valid

    transaction.as_hash.should == {
      input_total: 8_5000_0000,
      output_total: 8_4999_0000,
      fee: 10000,
      outputs: [
        ["bchtest:qpaps04mxmjkv4xmhua7hmmww4999wlcl5sewjt0m0", 750000000],
        ["bchtest:qp82lfltxpfjmr02aqx93kmwe6a32qtkucp4e2cgyd", 99990000]
      ],
      trezor_outputs: [
        { script_type: 'PAYTOADDRESS',
          address: "bchtest:qpaps04mxmjkv4xmhua7hmmww4999wlcl5sewjt0m0",
          amount: "750000000" },
        { script_type: 'PAYTOADDRESS',
          address: "bchtest:qp82lfltxpfjmr02aqx93kmwe6a32qtkucp4e2cgyd",
          amount: "99990000" },
      ],
      inputs: [
        [ "bchtest:pza05cp9mshq7xx5h8e95cwsgv9lv0dhgyux7cru05",
          "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1, 200000000,
          "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "bchtest:pza05cp9mshq7xx5h8e95cwsgv9lv0dhgyux7cru05",
          "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1, 200000000,
          "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "bchtest:pza05cp9mshq7xx5h8e95cwsgv9lv0dhgyux7cru05",
          "1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 1, 200000000,
          "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "bchtest:qp82lfltxpfjmr02aqx93kmwe6a32qtkucp4e2cgyd",
          "9gb1op2beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 0, 150000000,
          "19ag1420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "bchtest:pqgn6cjf37zdk79asdh3ng44tesn648xscf0nw69xk",
          "eeeb30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968eee", 0, 100000000,
          "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"]
      ],

      trezor_inputs: [
        { address_n: [42,1,1],
          prev_hash: "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          prev_index: 1,
          amount: "200000000"
        },
        { address_n: [42,1,1],
          prev_hash: "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72",
          prev_index: 1,
          amount: "200000000"
        },
        { address_n: [42, 1, 1],
          prev_hash: "1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055",
          prev_index: 1,
          amount: "200000000"
        },
        { address_n: [41, 1, 1],
          prev_hash: "9gb1op2beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055",
          prev_index: 0,
          amount: "150000000"
        },
        { address_n: [42,1,1],
          prev_hash: "eeeb30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968eee",
          prev_index: 0,
          script_type: 'SPENDMULTISIG',
          amount: "100000000",
          multisig: {
            signatures: ['','',''],
            m: 2,
            pubkeys: [
              { address_n: [42,1,1],
                node: {
                  chain_code: 'a6d47170817f78094180f1a7a3a9df7634df75fa9604d71b87e92a5a6bf9d30a',
                  depth: 0, 
                  child_num: 0, 
                  fingerprint: 0,
                  public_key: '03142b0a6fa6943e7276ddc42582c6b169243d289ff17e7c8101797047eed90c9b',
                }
              },
              { address_n: [42,1,1],
                node: {
                  chain_code: '8c9151740446b9e0063ca934df66c5e14121a0b4d8a360748f1b19bfef675460',
                  depth: 0, 
                  child_num: 0, 
                  fingerprint: 0,
                  public_key: '027565ceb190647ec5c566805ebc5cb6166ae2ee1d4995495f61b9eff371ec0e61',
                }
              },
              { address_n: [42,1,1],
                node: {
                  chain_code: 'de5bc5918414df3777ff52ae733bdbc87431485cfd39aea65da6133e183ef68a',
                  depth: 0, 
                  child_num: 0, 
                  fingerprint: 0,
                  public_key: '028776ff18f0f3808d6d42749a6e2baee5c75c3f7ae07445403a3a5690d580a0af',
                }
              }
            ]
          }
        }
      ],
      transactions: [
        { hash: "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72",
          version: "1",
          lock_time: "0",
          inputs: [
            { prev_hash: "77de49d0db6afc2e682af6d04644fb76d1149c29e495422288691c64b130f602",
              prev_index: 1, sequence: "\\xffffffff", script_sig: "SCRIPTSCRIPTSCRIPT"},
            { prev_hash: "ed8c8213cc2d214ad2f293caae99e26e2c59d158f3eda5d9c1292e0961e20e76",
              prev_index: 1, sequence: "\\xffffffff", script_sig: " SCRIPTSCRIPTSCRIPT"}
          ],
          bin_outputs: [
            {amount: 1124635, script_pubkey: "5c78373661393134..."},
            {amount: 390243, script_pubkey: "5c78613931346261..."}
          ]
        },
        { hash: "1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055",
          version: "1",
          lock_time: "0",
          inputs: [
            { prev_hash: "75e927383b4c53f54ff5d694ebf1ba36753284d0c41ef9a18b9955595e0128cd",
              prev_index: 1, sequence: "\\xffffffff", script_sig: "SCRIPTSCRIPTSCRIPT"},
            { prev_hash: "c143483bfac3194aaaab0189f315679fe419bfd853a442643e70dc6911f5d7d2",
              prev_index: 1, sequence: "\\xffffffff", script_sig: "SCRIPTSCRIPTSCRIPT"}
          ],
          bin_outputs: [
            {amount: 237888, script_pubkey: "5c7861393134..."},
            {amount: 1032476, script_pubkey: "5c7837366139..."}
          ]
        },
        { hash: "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          version: "1",
          lock_time: "0",
          inputs: [
            { prev_hash: "158d6bbe586b4e00347f992e8296532d69f902d0ead32d964b6c87d4f8f0d3ea",
              prev_index: 0,
              sequence: "\\xffffffff",
              script_sig: "SCRIPTSCRIPTSCRIPT"
            }
          ],
          bin_outputs: [
            { amount: 4814421497, script_pubkey: "5c7837366139..." },
            { amount: 681715, script_pubkey: "5c7861393134..."}
          ]
        },
        { "hash": "9gb1op2beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055",
          "version": "1",
          "lock_time": "0",
          "inputs": [
            { "prev_hash": "158d6bbe586b4e00347f992e8296532d69f902d0ead32d964b6c87d4f8f0d3ea",
              "prev_index": 0, "sequence": "\\xffffffff", "script_sig": "SCRIPTSCRIPTSCRIPT" }
          ],
          "bin_outputs": [
            { "amount": 4814421497, "script_pubkey": "5c7837366139..." },
            { "amount": 681715, "script_pubkey": "5c7861393134..." }
          ]
        },
        { hash: "eeeb30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968eee",
          version: "1",
          lock_time: "0",
          inputs: [
            { prev_hash: "158d6bbe586b4e00347f992e8296532d69f902d0ead32d964b6c87d4f8f0d3ea",
              prev_index: 0,
              sequence: "\\xffffffff",
              script_sig: "SCRIPTSCRIPTSCRIPT" }
          ],
          bin_outputs: [
            { amount: 1_0000_0000, script_pubkey: "5c7837366139..." },
          ]
      }
      ],
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1],
        ["1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 1],
        ["9gb1op2beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 0],
        ["eeeb30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968eee", 0],
      ],
    }
  end

  it 'uses supplied inputs' do
    xpub1 = 'xpub661MyMwAqRbcGCmcnz4JtnieVyuvgQFGqZqw3KS1g9khndpF3segkAYbYCKKaQ9Di2ZuWLaZU4Axt7TrKq41aVYx8XTbDbQFzhhDMntKLU5'
    xpub2 = 'xpub661MyMwAqRbcFwc3Nmz8WmMU9okGmeVSmuprwNHCVsfhy6vMyg6g79octqwNftK4g62TMWmb7UtVpnAWnANzqwtKrCDFe2UaDCv1HoErssE'
    xpub3 = 'xpub661MyMwAqRbcGkqPSKVkwTMtFZzEpbWXjM4t1Dv1XQbfMxtyLRGupWkp3fcSCDtp6nd1AUrRtq8tnFGTYgkY1pB9muwzaBDnJSMo2rVENhz'
    addresses = [
      ['bchtest:qp82lfltxpfjmr02aqx93kmwe6a32qtkucp4e2cgyd', [41, 1, 1]],
      ['bchtest:pza05cp9mshq7xx5h8e95cwsgv9lv0dhgyux7cru05', [42, 1, 1]],
      [[xpub1, xpub2, xpub3], [42, 1, 1], 2]
    ]
    outputs = [["bchtest:qpaps04mxmjkv4xmhua7hmmww4999wlcl5sewjt0m0", 7_5000_0000]]
    transaction = Pochette::BchTrezorTransactionBuilder.new(
      inputs: (list_unspent_mock + list_unspent_multisig_mock).map { |utxo|
        utxo.tap { |u| u[0] = Cashaddress.from_legacy(u[0]) }
      },
      bip32_addresses: addresses,
      outputs: outputs,
      transactions: list_transactions_mock
    )
    expect(transaction).to be_valid
    expect(Pochette::BchTrezorTransactionBuilder.backend.backend).not_to have_received :list_unspent
    expect(Pochette::BchTrezorTransactionBuilder.backend.backend).not_to have_received :list_transactions
  end

  it 'receives bip32 addresses and formats output for trezor connect' do
    xpub1 = 'xpub661MyMwAqRbcGCmcnz4JtnieVyuvgQFGqZqw3KS1g9khndpF3segkAYbYCKKaQ9Di2ZuWLaZU4Axt7TrKq41aVYx8XTbDbQFzhhDMntKLU5'
    xpub2 = 'xpub661MyMwAqRbcFwc3Nmz8WmMU9okGmeVSmuprwNHCVsfhy6vMyg6g79octqwNftK4g62TMWmb7UtVpnAWnANzqwtKrCDFe2UaDCv1HoErssE'
    xpub3 = 'xpub661MyMwAqRbcGkqPSKVkwTMtFZzEpbWXjM4t1Dv1XQbfMxtyLRGupWkp3fcSCDtp6nd1AUrRtq8tnFGTYgkY1pB9muwzaBDnJSMo2rVENhz'
    addresses = [
      ['bchtest:qp82lfltxpfjmr02aqx93kmwe6a32qtkucp4e2cgyd', [41, 1, 1]],
      ['bchtest:pza05cp9mshq7xx5h8e95cwsgv9lv0dhgyux7cru05', [42, 1, 1]],
      [[xpub1, xpub2, xpub3], [42, 1, 1], 2]
    ]
    outputs = [["bchtest:qpaps04mxmjkv4xmhua7hmmww4999wlcl5sewjt0m0", 7_5000_0000]]
    transaction = Pochette::BchTrezorTransactionBuilder
      .new(bip32_addresses: addresses,
           outputs: outputs,
           trezor_connect: true)
    transaction.should be_valid

    transaction.as_hash.should == {
      input_total: 8_5000_0000,
      output_total: 8_4999_0000,
      fee: 10000,
      outputs: [
        ["bchtest:qpaps04mxmjkv4xmhua7hmmww4999wlcl5sewjt0m0", 750000000],
        ["bchtest:qp82lfltxpfjmr02aqx93kmwe6a32qtkucp4e2cgyd", 99990000]
      ],
      trezor_outputs: [
        { script_type: 'PAYTOADDRESS',
          address: "bchtest:qpaps04mxmjkv4xmhua7hmmww4999wlcl5sewjt0m0",
          amount: "750000000" },
        { script_type: 'PAYTOADDRESS',
          address: "bchtest:qp82lfltxpfjmr02aqx93kmwe6a32qtkucp4e2cgyd",
          amount: "99990000" },
      ],
      inputs: [
        [ "bchtest:pza05cp9mshq7xx5h8e95cwsgv9lv0dhgyux7cru05",
          "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1, 200000000,
          "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "bchtest:pza05cp9mshq7xx5h8e95cwsgv9lv0dhgyux7cru05",
          "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1, 200000000,
          "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "bchtest:pza05cp9mshq7xx5h8e95cwsgv9lv0dhgyux7cru05",
          "1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 1, 200000000,
          "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "bchtest:qp82lfltxpfjmr02aqx93kmwe6a32qtkucp4e2cgyd", 
          "9gb1op2beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 0, 150000000, 
          "19ag1420993489de25302418540f4b410c0c1d3e1d05a988ac"],
        [ "bchtest:pqgn6cjf37zdk79asdh3ng44tesn648xscf0nw69xk",
          "eeeb30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968eee", 0, 100000000,
          "76a91420993489de25302418540f4b410c0c1d3e1d05a988ac"]
      ],
      trezor_inputs: [
        { address_n: [42,1,1],
          prev_hash: "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          prev_index: 1,
          amount: "200000000"
        },
        { address_n: [42,1,1],
          prev_hash: "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72",
          prev_index: 1,
          amount: "200000000"
        },
        { address_n: [42, 1, 1],
          prev_hash: "1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055",
          prev_index: 1,
          amount: "200000000"
        },
        { address_n: [41, 1, 1],
          prev_hash: "9gb1op2beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055",
          prev_index: 0,
          amount: "150000000"
        },
        { address_n: [42,1,1],
          prev_hash: "eeeb30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968eee",
          prev_index: 0,
          script_type: 'SPENDMULTISIG',
          amount: "100000000",
          multisig: {
            signatures: ['','',''],
            m: 2,
            pubkeys: [
              { address_n: [42,1,1],
                node: {
                  chain_code: 'a6d47170817f78094180f1a7a3a9df7634df75fa9604d71b87e92a5a6bf9d30a',
                  depth: 0, 
                  child_num: 0, 
                  fingerprint: 0,
                  public_key: '03142b0a6fa6943e7276ddc42582c6b169243d289ff17e7c8101797047eed90c9b',
                }
              },
              { address_n: [42,1,1],
                node: {
                  chain_code: '8c9151740446b9e0063ca934df66c5e14121a0b4d8a360748f1b19bfef675460',
                  depth: 0, 
                  child_num: 0, 
                  fingerprint: 0,
                  public_key: '027565ceb190647ec5c566805ebc5cb6166ae2ee1d4995495f61b9eff371ec0e61',
                }
              },
              { address_n: [42,1,1],
                node: {
                  chain_code: 'de5bc5918414df3777ff52ae733bdbc87431485cfd39aea65da6133e183ef68a',
                  depth: 0, 
                  child_num: 0, 
                  fingerprint: 0,
                  public_key: '028776ff18f0f3808d6d42749a6e2baee5c75c3f7ae07445403a3a5690d580a0af',
                }
              }
            ]
          }
        }
      ],
      transactions: nil,
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1],
        ["1db1f22beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 1],
        ["9gb1op2beb84e5fbe92c8c5e6e7f43d80aa5cfe5d48d83513edd9641fc00d055", 0],
        ["eeeb30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968eee", 0],
      ],
    }
  end
end
