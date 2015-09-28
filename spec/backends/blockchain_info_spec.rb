require 'spec_helper'

describe Pochette::Backends::BlockchainInfo do
  before(:each){ Pochette::Backends::BlockchainInfo.cooldown = 0 }
  let(:addresses){
    # These next two may be included in stubbed outputs, like being watched
    # by the wallet but uninteresting to our code, we should
    # assert they are safely ignored.
    ['1E2joHn8qdujPKB9mq4xuiKquJoaUqikcA', '13nTbPSPug4f9FaLmqE4LaK6dddbzkG96v', '1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA', ]
  }

  let(:backend){ Pochette::Backends::BlockchainInfo.new }

  def stub_api(url, fixtures, options = {}, method = :get)
    responses = fixtures.collect do |f|
      path = File.join('../../fixtures/blockchain_info', f)
      {status: 200, body: open(File.expand_path(path, __FILE__))}
    end

    with = if method == :get
      options[:format] ||= 'json'
      { query: options }
    elsif method == :post
      { body: hash_including(options) }
    end

    stub_request(method, "https://blockchain.info/#{url}")
      .with(with).to_return(*responses)
  end

  it 'implements incoming_for' do
    Timecop.freeze Date.new(2000, 1, 1)
    stub_api('latestblock', ['latestblock'], {})
    stub_api('multiaddr', ['multiaddr_for_incoming_for'],
      {active: addresses.join('|')})
    backend.incoming_for(addresses, 30.days.ago).tap do |r|
      r.size.should == 21
      expected = [
        [ 121933781, "13nTbPSPug4f9FaLmqE4LaK6dddbzkG96v",
          "6be69eeb3fcbb67341a0869fefb2002ad68fae568690364358cf0bbe4b3e9cae", 5, 0,
          "1E2joHn8qdujPKB9mq4xuiKquJoaUqikcA,1JvTw8TDtG5rsL8gNt6TYhDbpfKVuch8G5"],
        [ 12095034, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "188ee2c06c7344cab974b124bbad31d6f5ec6026880bbff1ecee94366e76d488", 202, 0,
          "12ZZJ8Kexy8FepF2oguGacgFeStqKQgq4U,1JTosFM7kmarWQY8UNKbJwXXBoNk84AJnD,1MHyy9m25boQrx4pHPqiCrEX2Fv9rFfM3d"],
        [ 21092845, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "b22917327193fc11b341c60a00203a1c16a099788a8459950c9b421412aff894", 744, 1,
          "1NUMQwKufDnuKecitDvMiaMSwRyyhEt1Hb"],
        [ 867200, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "7b49751c459e1b5cac475262879572daaf0f8af56556a05a68579ad43bc77749", 869, 0,
          "19EKn9zSogbVugDU1LPYGLhiMV53gfFFfd,1CbwAnviUaeGmVFDfE8Qw9wPbv7YmURXcj"],
        [ 3306400, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "ed367f38cdcd972262c275ac031099a5528a5fe4420cec7d13d0a7150412c5a2", 980, 1,
          "18YCMYCeTdJCnBtTrYn5MKc6R1WeaYyexV,1KW18wvmvHNgTGUHhLaWMGa4ejCfcif6oC,1KGwXjGRNFGC7BzrCTZnHxSKp3jdicQQs8,1D3CPjgkeMW42UtJDfbW7tYZQVgcgZEGrH"],
        [ 874800, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "f655c975c52b2fb5586b9d04d768279ef3cbc487b7f74c3451fe61dcaa79eace", 987, 0,
          "1F3JWozjGvmSLBTYbPQNdq3i8GBZwSKHsB,16YvwRDyPqsMdgbTs7Lk7dzBxSEmYLLdFW"],
        [ 106955000, "1E2joHn8qdujPKB9mq4xuiKquJoaUqikcA",
          "93f0c1abc714e8241403a69e0fb6bc720105b518709e65f76e727f1d8a7df2c8", 1040, 0,
          "15m3ZphR5cYEiVe3FXBQecFuoKkaxqRAug,1KyUcpxzprfitsny6T2a9hLg98A7fVhz6f,14mCiYJTVteGrEvZPu4UgRGGar262wAhxT"],
        [ 864800, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "28c9eac2479fcaed8e0f98c2c9b83f3c20f521b8390c5f96e8992154ac96a2d7", 1165, 0,
          "1DftqX6ZzoatETBkKph8PKBKZo2BHq68BX,1JD8pwiFE812WonCXttJpGYzuA2pJaCVCU"],
        [ 2000000, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "7911d10faf4ec5d7700a63886a9930ee9cb54bd25346da785cd7cde55aaa752e", 1186, 0,
          "1BLxWM741VUXfYycbx9r9mjLvD2KR5tDNG,1Q3MEDBrxkERhy7xbPV3nqTGC3SuBXRVpW"],
        [ 5000000, "13nTbPSPug4f9FaLmqE4LaK6dddbzkG96v",
          "21e6da8432b3f4b5c4dd7863d5a959e6af3583230da398bd0e43c7636b28def4", 1209, 0,
          "1EGhW4YyPwekYzcG5UDSkt3xygwjUz5gTX,12bKjReb98L8kWySdQTKEkPZVMByd53TCE"],
        [ 2203952, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "5efea171cfd2f978657a119ede868a10d956ddad342bba784a7c374adb788f8c", 1512, 0,
          "18pX3THqk1QNGy7mSRsyLiJihxFhPte9WD,1KPBDUS3EEtHtZ6WTZHCfBMtycd9LzA7zr"],
        [ 8341973, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "adb267d46f6f2f3941e7f1d586d2b393624b7754185597047d092503320b6e34", 1644, 1,
          "145VrDvDqh1Ewng8TdE3XokT2AG2pM4DSw"],
        [ 4990800, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "189211319934f008a1f7670d59cd1da422eb88d5185d7a509d36905c434ef11e", 1651, 0,
          "1DXcPJgzSWC89paHC2TSJZNL4CWdVmarLR,1HeMRmyuawpQN6aBdWC6RYts6RZGpzfuez,12XLPpKdrcc66RTc7oNQt2731W1fM68bMG"],
        [ 6337415, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "ca7802705c730da59e911ebd58335ab97d72d55cf8241248f6ffb12c9cd0e8f7", 3017, 0,
          "1M6VUx8NznbNXnQZBjhUcuTkv6X7Ho3WYg,1AbPhoVvJkXwHGgzB7ReNZuk72mzSUFMkU"],
        [ 2177000, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "71817dfee5393cb5fa912a38e19024dcfbcac6dc9e136fcfac76e85c654a2453", 3030, 0,
          "1LendkZR2LpG7TvvF97TQoQPeKreZPqNbp,1KXs7RcnH4TaNYPXTyk4DZwSfamfjAPbry,1JARKkAWDRbjygJ7ERNZaqHVZYt3Ej8GLH"],
        [ 859400, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "82418fb953064d78cc8f0a42bbe5ef93bd8320a90d2d88fd38f33071634fbe68", 3783, 0,
          "193DKu6Jd8wch49ANcVEt59DWqEM86MbWF,1A8HjqfbWMovnZpyfpME7Qwd7N7QwgLcch"],
        [ 9000000, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "d9b58346e27eb73d2fe26bee89a85a187b9a4ac62eedecdcbc0939694c424f68", 4097, 0,
          "3GaQ94d6MsvHvtYs22aPBFhMxaQeXphbqC"],
        [ 873000, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "1a79a07a3239c3d02b1bf1b14a1d2f54e9473e2e45b3a5028b968c705935e6a7", 4192, 0,
          "1CbusohL7epbTQUHMnCpCi4eSBZzjNAw6W,19DDRjEkPykHuN2uf51fsXRkznxH8Uxm5o"],
        [ 4653760, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "19b8a7be6df5f699cb4512908d9747208e794f0c1ee3a379f3a63466ce284d00", 4803, 0,
          "3MW4yoeJmCrUyQzpx8Zbb3VmBbJ8hzwUod"],
        [ 4673334, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "db1c0509c273cc68835169b063d1b1fde1afdfbdda1d24b47aabd61c9ab1fc43", 4808, 1,
          "3CPeMvrVYhqVzkgnVFb7JMCThnhLyt4pJn"],
        [ 111784, "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA",
          "27006b362686b6bae74936009cdb4b97219d45bcaf490c839c2b9f49d0788815", 4812, 1,
          "3Jb5RJbueLynTgx4xgrn8jCtmTiHCsuC2S"]
      ]
      expected.zip(r).each do |a,b|
        a.should == b
      end
    end
  end
  
  it 'implements balances_for' do
    stub_api('multiaddr', ['multiaddr_for_incoming_for'],
      {active: addresses.join('|')})

    addresses.each do |addr|
      stub_api("q/getreceivedbyaddress/#{addr}",
        ["getreceivedbyaddress_#{addr}"], {confirmations: 3})
      stub_api("q/getsentbyaddress/#{addr}",
        ["getsentbyaddress_#{addr}"], {confirmations: 3})
    end

    backend.balances_for(addresses, 3).should == {
      "1J8UUif2FCzCfMkRyQ49KyaeGWz8ZGj8WA" =>
        [0.85323497, 0.85323497, 0, 0.85323497, 0.85323497, 0],
      "13nTbPSPug4f9FaLmqE4LaK6dddbzkG96v" =>
        [1.16933781, 1.06933781, 0.1, 1.26933781, 1.26933781, 0],
      "1E2joHn8qdujPKB9mq4xuiKquJoaUqikcA" => 
        [1.06955000, 1.06955000, 0, 1.06955000, 1.06955000, 0]
    }
  end
  
  it 'implements list_unspent' do
    addresses = ['13yNA2RMSxVDga6AmixwumacqCxbjcmnwi', '1EMTe38Dwq9zHXktd6jtfxtGPbxHmFMdwM']
    stub_api('unspent', ['list_unspent'], {active: addresses.join('|')} )
    backend.list_unspent(addresses).should == [
      ["1EMTe38Dwq9zHXktd6jtfxtGPbxHmFMdwM",
        "f394d5c739b7780262c9b382605538ae1189ba0133251891f76c6ab7084621df", 0, 300000000],
      ["1EMTe38Dwq9zHXktd6jtfxtGPbxHmFMdwM",
        "c78142666e2f3376aa2cb9614a847be9e3daa6eeba25105f71445b58375a4c37", 0, 200000000],
      ["1EMTe38Dwq9zHXktd6jtfxtGPbxHmFMdwM",
        "d529b9ffd6d5dcd0c431fddd05849846935de3bb89d67831d971b2f2584cdde8", 0, 164486111],
      ["1EMTe38Dwq9zHXktd6jtfxtGPbxHmFMdwM",
        "e19798db667374abab2daf6028249cfb020c78c7e8a46e5a2a93eb53d48f6ff6", 0, 335513889],
      ["1EMTe38Dwq9zHXktd6jtfxtGPbxHmFMdwM",
        "f90ec5a88df5933c3b3295a0ff515085e4ed0661b4049d8a51d2ef0031e96266", 0, 225000000],
      ["13yNA2RMSxVDga6AmixwumacqCxbjcmnwi",
        "199e70bfc46d52bb452b144061c26cc9ff74dd9befae869e1df8d25e00e89861", 0, 2699995900]
    ]
  end
  
  it 'implements list_transactions' do
    %w(73134072 73167152 73167153 73340727 73378186
    878b60d33419cf7fa0972900481a4c281b4646425d49acb11f93d1765b783793
    f394d5c739b7780262c9b382605538ae1189ba0133251891f76c6ab7084621df).each do |tx|
      stub_api("rawtx/#{tx}", ["rawtx_#{tx}"])
    end
    txids = [
      '878b60d33419cf7fa0972900481a4c281b4646425d49acb11f93d1765b783793',
      'f394d5c739b7780262c9b382605538ae1189ba0133251891f76c6ab7084621df',
    ]
    backend.list_transactions(txids).should == [
      { :hash=>"878b60d33419cf7fa0972900481a4c281b4646425d49acb11f93d1765b783793",
        :version=>1, :lock_time=>0,
        :inputs=> [
          { :prev_hash=>"3570a12a00b691300eaf7ef97331e71021a8c7dbc35cd379ce1db6ad7240e0da",
            :prev_index=>0, :sequence=>4294967295,
            :script_sig=>"47304402206bf1af7abd034f771be73b45a9f01a64782aecbfa1240c5a55931cf40056595d0220067af8bb3ba33a71b73ce2bff473073cb2f158fce52b61b785efd2c6e66e7d64014104c82c53a0cd486a482e1da40cfbebf23d73a3488ea5ef49ba462264d94620fd307fa37b367462f5ff3a03807c811ebf8639d2555b3599a46e013f1dd2f104376a"},
          { :prev_hash=>"8d1b1d5ba5205f30a381fb69ad859aa1218aea3c58db14f2a60de45102c5980a",
            :prev_index=>2, :sequence=>4294967295,
            :script_sig=>"473044022044d61fff105351a2ed15137549ca94d08f6d88b9d0dd0b7072aaea061375db6902203dc33eec1e35b62980568a4f07c3115e4ab20712ec7c7854d755943b511f6516014104d85fcb62e4d9bccdb1176134de42d818e674929743b9583478f48421f99d9040900b834b93cd339e671838a3c96b9de77444b35e76e96455fb4734757fbfe829"}
        ],
        :bin_outputs=>[
          {:amount=>100000000, :script_pubkey=>"76a91452935f9c6223f6b111bc1c9809d8e48a08e19ba888ac"},
          {:amount=>4941534, :script_pubkey=>"76a914eef4ed77bee94a7fb7e026744124516b3aefc5a188ac"},
          {:amount=>180766, :script_pubkey=>"76a9145d0385c08c122ec029cb6c8424de7bd83d9aabe088ac"}
        ]
      },
      { :hash=>"f394d5c739b7780262c9b382605538ae1189ba0133251891f76c6ab7084621df",
        :version=>1, :lock_time=>0,
        :inputs=>[
          { :prev_hash=>"878b60d33419cf7fa0972900481a4c281b4646425d49acb11f93d1765b783793",
            :prev_index=>1, :sequence=>4294967295,
            :script_sig=>"493046022100dee53517af4588e3a9fd1e937065d06d5a4d0dc099c3b7ff50cbecc91ddc4840022100ccaa6c56b2dcff2e176d0266435c72be44b0031d23b29a4678d91a6e2d6aa5f50141045550369ec897ef63b9275a47d88c68c5b249bee9408f87af6180cdeca1a5f178cc3fd1d795c9765b45385cde9d791d852c1b6da17555e45bc901b6d7c6e4ca93"},
          { :prev_hash=>"06d9d538e708093b688b262fb01e16f360f1ebfb12f0e5de419e6fab148df776",
            :prev_index=>0, :sequence=>4294967295,
            :script_sig=>"473044022100e7f35bae2151ce764ea77b5e16de7343b5787a2dd477927ea1a2ecd8e329b69d021f5295d370373c0710354469899c6a173c4924fd1b2bce57f63d50ebd6771e2b014104c3c69c47c74d6cdc6607b74a201674dfa07f2a87ec6c5191cd6ba47d36642429671c9486eb5157739b14f6c9a98571dcf4fab6c3ce6037afdcc4149d7469fb36"},
          { :prev_hash=>"eb9db69a86b615397b6e5a1b6e51228e708d486cdba7d913dc8f1f4d60e97e29",
            :prev_index=>1, :sequence=>4294967295,
            :script_sig=>"483045022012ceaf9ada4435997dd30f8a651e62a160d0376e5fa6837dca107b7facd06f12022100d4967f7c0856fc7bb7fb573d370564804a0974f68bfd0147c96e82f965e4fea4014104c8a6bc102b0437822c6ba51329b89fda88be0530c87600a11a325826b95d42fac26e958bd4d399c34051d73212cb70721092004d391d8a4ab120ca555f44f630"}
        ],
        :bin_outputs=>[
          {:amount=>300000000, :script_pubkey=>"76a914927830f0fb997fffb91ca7fd341bf96bb2e5743b88ac"},
          {:amount=>29900, :script_pubkey=>"76a914fee327d1f6c660e9f3eefa1eee328b83c9c96b9e88ac"}
        ]
      }
    ]
  end

  it 'gets block height' do
    stub_api('latestblock', ['latestblock'], {})
    backend.block_height.should == 375805
  end

  it 'implements pushtx' do
    hex = "0100000001d11a6cc978fc41aaf5b24fc5c8ddde71fb91ffdba9579cd62ba20fc284b2446c000000008a47304402206d2f98829a9e5017ade2c084a8b821625c35aeaa633f718b1c348906afbe68b00220094cb8ee519adcebe866e655532abab818aa921144bd98a12491481931d2383a014104e318459c24b89c0928cec3c9c7842ae749dcca78673149179af9155c80f3763642989df3ffe34ab205d02e2efd07e9a34db2f00ed8b821dd5bb087ff64df2c9effffffff0280f0fa02000000001976a9149b754a70b9a3dbb64f65db01d164ef51101c18d788ac40aeeb02000000001976a914aadf5d54eda13070d39af72eb5ce40b1d3b8282588ac00000000"
    stub_api('pushtx', ['pushtx'], {tx: hex}, :post)
    backend.pushtx(hex).should == 'fb92420f73af6d25f5fab93435bc6b8ebfff3a07c02abd053f0923ae296fe380'
  end

  it 'can use an api_code' do
    backend = Pochette::Backends::BlockchainInfo.new('my_api_code')
    stub_api('latestblock', ['latestblock'], {api_code: 'my_api_code'})
    backend.block_height.should == 375805
  end
end
