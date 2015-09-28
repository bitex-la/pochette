require 'spec_helper'

describe Pochette::Backends::BitcoinCore do
  let(:addresses){
    # These next two may be included in stubbed outputs, like being watched
    # by the wallet but uninteresting to our code, we should
    # assert they are safely ignored.
    # mimKonWQJZLGstKgjsUxxqoN2uTo75dW7c
    # mznwgDb5Zin5SLgmDgTaCcZDxQpeQjMJsp
    ['mjfa56Keq7PXRKgdPSDB6eWLp4aaAVcj6L', 
    'mwZE4QfzzriE7nsgHSWbgmtT7s6SDysYvP',
    'mvrDG7Ts6Mq9ejhZxdsQLjbScycVaktqsg',
    'mxYzRdJfPk8PcaKSsSzNkX85mMfNcr2CGr',
    'mzbXim4u1Nq4J2kVggu471pZL3ahxNkmE9',
    'mhLAgRz5f1YogfYBZCDFSRt3ceeKBPVEKg'
    ]
  }

  let(:rpc_url){ 'http://user:pass@server:12345' }

  let(:backend){ Pochette::Backends::BitcoinCore.new(rpc_url) }

  def stub_rpc(method, params, *fixtures)
    request = {id: 'jsonrpc', method: method}
    request[:params] = params unless params.empty?
    responses = fixtures.collect do |f|
      path = File.expand_path(File.join('../../fixtures/', f), __FILE__)
      {status: 200, body: open(path)}
    end

    stub_request(:post, rpc_url)
      .with(body: hash_including(request)).to_return(*responses)
  end

  it 'implements incoming_for' do
    Timecop.freeze Date.new(2000, 1, 1)
    stub_rpc('getblockcount', [], 'getblockcount')
    stub_rpc('getblockhash', [500137], 'getblockhash')
    stub_rpc('listsinceblock',
      ["0000000000000a4b4782fbbaabc7080ff2d7fa484b848ee4f1ff3d36c41e4ffb", 1, true],
      'listsinceblock')
    stub_rpc('getrawtransaction', {},
      *(12.times.collect{|i| "incoming_for_getrawtransaction_#{i}" }))
    backend.incoming_for(addresses, 30.days.ago).tap do |r|
      r.size.should == 6
      r.should == [
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
    end
  end
  
  it 'implements balances_for' do
    stub_rpc('listreceivedbyaddress', [3, false, true], 'listreceivedbyaddress3')
    stub_rpc('listreceivedbyaddress', [0, false, true], 'listreceivedbyaddress0')
    stub_rpc('listunspent', [0,99999999, addresses], 'balances_for_listunspent')

    backend.balances_for(addresses, 3).should == {
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
  end
  
  it 'implements list_unspent' do
    stub_rpc('listunspent', [1, 99999999, addresses], 'list_unspent_listunspent')
    backend.list_unspent(addresses).should == [
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
  end
  
  it 'implements list_transactions' do
    stub_rpc('getrawtransaction', {},
      *(7.times.collect{|i| "list_unspent_getrawtransaction_#{i}" }))
    txids = [
      "fb401691795a73e0160252c00af18327a15006fcdf877ccca0c116809669032e",
      "250978b77fe1310d6c72239d9e9589d7ac3dc6edf1b2412806ace5104553da34",
      "d9afd460b0a5e065fdd87bf97cb1843a29ea588c59daabd1609794e8166bb75f",
      "5bd72a4aa7818f47ac8943e3e17519be00c46530760860e608d898d728b9d46e",
      "b252037526ecb616ab5901552abb903f00bf73400a1fc49b5b5bd699b84bce77",
      "9142d7a8e96124a36db9708dd21afa4ac81f15a77bd85c06f16e808a4d700da2",
      "ff768084764a05d1de72628432c0a4419538b2786089ec8ad009f6096bc69fe1",
    ]
    backend.list_transactions(txids).should == [
      {:hash=>"fb401691795a73e0160252c00af18327a15006fcdf877ccca0c116809669032e", :version=>1,
      :lock_time=>0,
      :inputs=>[{:prev_hash=>"f948600a52719ec63947bd47105411c2cb032bda91b08b25bb7b1de22f1f7458",
      :prev_index=>1, :sequence=>4294967295,
      :script_sig=>"483045022100898b773c1cf095d5c1608a892673ad067387663e00327e7b88dd48cc4eb9cf2a02203a53336afd4440ea52c6a55e07ac60035dc386cb01b5b6810efac018f0346fad01210316cff587a01a2736d5e12e53551b18d73780b83c3bfb4fcf209c869b11b6415e"}],
      :bin_outputs=>[{:amount=>500000,
      :script_pubkey=>"76a9142d81b210deb7e22475cd7f2fda0bf582dddc9da788ac"}, {:amount=>276607256,
      :script_pubkey=>"76a914c01a7ca16b47be50cbdbc60724f701d52d75156688ac"}]},
      {:hash=>"250978b77fe1310d6c72239d9e9589d7ac3dc6edf1b2412806ace5104553da34", :version=>1,
      :lock_time=>0,
      :inputs=>[{:prev_hash=>"8505c663d0414b678827eed85ba9e7652e616c19ff1be871f6b083d5ed400a20",
      :prev_index=>0, :sequence=>4294967295,
      :script_sig=>"47304402203ac7cb9afe1a14189b63807aff301ef6bb8507f6dc0471bcee5362282a8c3e38022012c3bfe9680f013735f0d6d012d6420383c0e3a1dbf010f97be9cc834a93d1f601210221af8672ff613d2ea198d8dadcc387a36ef47d7cba6f541221db61b96aa20149"}],
      :bin_outputs=>[{:amount=>999293000,
      :script_pubkey=>"76a91426beab63a5fb7b2103929e91b65f339a2c5b285088ac"}, {:amount=>100000,
      :script_pubkey=>"76a914badcbfae4d83a52dc2c8f68605663adc9d4922a688ac"}]},
      {:hash=>"d9afd460b0a5e065fdd87bf97cb1843a29ea588c59daabd1609794e8166bb75f", :version=>1,
      :lock_time=>0,
      :inputs=>[{:prev_hash=>"03b833938e7925b1b5d9d905e11efc9a7980760c753ee4ca20781c51a531b5c2",
      :prev_index=>1, :sequence=>4294967295,
      :script_sig=>"483045022100bec73d4a4394c758ff51c9f9961941dfc234be5c4b094f3e08e0848402b0d44d022074e3c9225d607521e2a31ece550b13c8ec6d217ed92079c488c407d79931ea1701210316cff587a01a2736d5e12e53551b18d73780b83c3bfb4fcf209c869b11b6415e"}],
      :bin_outputs=>[{:amount=>500000,
      :script_pubkey=>"76a914a82e489066cc8172d1afaa84b96fa9613cd0955688ac"}, {:amount=>1234639997,
      :script_pubkey=>"76a914c01a7ca16b47be50cbdbc60724f701d52d75156688ac"}]},
      {:hash=>"5bd72a4aa7818f47ac8943e3e17519be00c46530760860e608d898d728b9d46e", :version=>1,
      :lock_time=>0,
      :inputs=>[{:prev_hash=>"890e8cdd490fef3c5b1af193d56a09b0fa0f8dab0901640569016cf3b38ea3ac",
      :prev_index=>0, :sequence=>4294967295,
      :script_sig=>"4730440220365e2375c84c5079b32579921b174decd37c18bb8f348fb482e50f8924e4490b022072198be9e61696ac8884b4d51dfa4097d73ba48804bb004841db27e88890f6cd012103267b8160b27c359d640f19eab29fc08fa39f10b253fd28608f2555272f60b9b1"}],
      :bin_outputs=>[{:amount=>998485000,
      :script_pubkey=>"76a914dbb90fb145460968c3aabefadfe96cfd36af255288ac"}, {:amount=>100000,
      :script_pubkey=>"76a914badcbfae4d83a52dc2c8f68605663adc9d4922a688ac"}]},
      {:hash=>"b252037526ecb616ab5901552abb903f00bf73400a1fc49b5b5bd699b84bce77", :version=>1,
      :lock_time=>0,
      :inputs=>[{:prev_hash=>"242ff59e8da7492b7c2d91dba705115734d44b67fb58321269add13914c4f244",
      :prev_index=>1, :sequence=>4294967295,
      :script_sig=>"483045022100bcd5444965ff1103bbd00b19e8eac252a07ae7fb2f7ad1a05c31f4a3b6efadf70220768947a55baa54b746e163b6a4bdbf06e0c69b00bfd2ce186bfce9032774900701210316cff587a01a2736d5e12e53551b18d73780b83c3bfb4fcf209c869b11b6415e"}],
      :bin_outputs=>[{:amount=>500000,
      :script_pubkey=>"76a914aff00113ae336461aa1613eac95c3279b533279388ac"}, {:amount=>317599996,
      :script_pubkey=>"76a914c01a7ca16b47be50cbdbc60724f701d52d75156688ac"}]},
      {:hash=>"9142d7a8e96124a36db9708dd21afa4ac81f15a77bd85c06f16e808a4d700da2", :version=>1,
      :lock_time=>0,
      :inputs=>[{:prev_hash=>"a33053a1dfc95c666f50002e2d0be0aeca7af7d3178bcce5cd91e21cca6455ae",
      :prev_index=>0, :sequence=>4294967295,
      :script_sig=>"47304402206ae6b2e555525eeabd806fc3215ea0071d1d1e3224853e9de4ab47b98464a388022021ffc98dcd7347d138f616b23f97a0662c52b5995a8b0595d7eb4b18189a1581012103026c4bc4a4f3cb13c92700692e5e2269313987e77fbc5d35ac9f01d57d8d7731"}],
      :bin_outputs=>[{:amount=>997374000,
      :script_pubkey=>"76a914bc0aaf1644d918489803b223bd5aabdd9deef8b388ac"}, {:amount=>100000,
      :script_pubkey=>"76a9142d81b210deb7e22475cd7f2fda0bf582dddc9da788ac"}]},
      {:hash=>"ff768084764a05d1de72628432c0a4419538b2786089ec8ad009f6096bc69fe1", :version=>1,
      :lock_time=>0,
      :inputs=>[{:prev_hash=>"0c8a9a0c31d19c02deabb0faee6860368fd194bf549cf63fccdbffda41c25354",
      :prev_index=>1, :sequence=>4294967295,
      :script_sig=>"47304402200d9d4e05ed741f7b2a2a2321b9afb786e9144bf440bbb0ba89ea659e5d55ab1e022017e9f8fcef318c50239bcad0f15b5b24c3a1b88bf7d322e8f9a8f9662a5640d501210316cff587a01a2736d5e12e53551b18d73780b83c3bfb4fcf209c869b11b6415e"}],
      :bin_outputs=>[{:amount=>500000,
      :script_pubkey=>"76a914d147f4d2921056aa6d8c6a57f8aad4d68523959e88ac"}, {:amount=>603582319,
      :script_pubkey=>"76a914c01a7ca16b47be50cbdbc60724f701d52d75156688ac"}]}]
  end

  it 'implements block height' do
    stub_rpc('getinfo', [], 'getinfo')
    backend.block_height.should == 315281
  end

  it 'implements pushtx' do
    stub_rpc('sendrawtransaction', [], 'sendrawtransaction')
    backend.pushtx('sometransaction').should == 'f5a5ce5988cc72b9b90e8d1d6c910cda53c88d2175177357cc2f2cf0899fbaad'
  end
end
