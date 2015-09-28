require 'spec_helper'

describe Pochette::TrezorTransactionBuilder do
  before(:each) do
    Pochette.backend = double(
      list_unspent: list_unspent_mock,
      list_transactions: list_transactions_mock
    )
  end
  after(:each){ Pochette.backend = nil }

  it 'receives bip32 addresses and formats output for trezor' do
    addresses = [["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", [42, 1, 1]]]
    outputs = [["1Gaor6PAAP3bV4aks6ydKHKEwiF7GfXTTF", 3_0000_0000]]
    transaction = Pochette::TrezorTransactionBuilder
      .new(bip32_addresses: addresses, outputs: outputs)
    transaction.should be_valid

    transaction.as_hash.should == {
      input_total: 4_0000_0000,
      output_total: 3_9999_0000,
      fee: 10000,
      outputs: [
        ["1Gaor6PAAP3bV4aks6ydKHKEwiF7GfXTTF", 300000000], 
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9", 99990000]
      ],
      trezor_outputs: [
        { script_type: 'PAYTOADDRESS',
          address: "1Gaor6PAAP3bV4aks6ydKHKEwiF7GfXTTF",
          amount: 3_0000_0000 },
        { script_type: 'PAYTOSCRIPTHASH',
          address: "2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          amount: 9999_0000 },
      ],
      inputs: [
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1, 200000000],
        ["2NAHscN6XVqUPzBSJHC3fhkeF5SQVxiR9p9",
          "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1, 200000000]
      ],
      trezor_inputs: [
        { address_n: [42,1,1],
          prev_hash: "956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40",
          prev_index: 1},
        { address_n: [42,1,1],
          prev_hash: "0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72",
          prev_index: 1},
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
        }
      ],
      utxos_to_blacklist: [
        ["956b30c3c4335f019dbee60c60d76994319473acac356f774c7858cd5c968e40", 1],
        ["0ded7f014fa3213e9b000bc81b8151bc6f2f926b9afea6e3643c8ad658353c72", 1],
      ],
    }
  end
end
