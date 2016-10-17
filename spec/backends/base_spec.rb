require 'spec_helper'

describe Pochette::Backends::Base do
  let(:hex) { "0100000001d11a6cc978fc41aaf5b24fc5c8ddde71fb91ffdba9579cd62ba20fc284b2446c000000008a47304402206d2f98829a9e5017ade2c084a8b821625c35aeaa633f718b1c348906afbe68b00220094cb8ee519adcebe866e655532abab818aa921144bd98a12491481931d2383a014104e318459c24b89c0928cec3c9c7842ae749dcca78673149179af9155c80f3763642989df3ffe34ab205d02e2efd07e9a34db2f00ed8b821dd5bb087ff64df2c9effffffff0280f0fa02000000001976a9149b754a70b9a3dbb64f65db01d164ef51101c18d788ac40aeeb02000000001976a914aadf5d54eda13070d39af72eb5ce40b1d3b8282588ac00000000" }

  describe '#verify_signatures' do
    it 'returns true for valid signatures' do
      prev_tx = { bin_outputs: [ { amount: 100000000, script_pubkey: '76a914aadf5d54eda13070d39af72eb5ce40b1d3b8282588ac' } ] }
      expect(subject).to receive(:list_transactions) { [ prev_tx ] }
      expect do
        subject.verify_signatures(hex)
      end.not_to raise_error
    end

    it 'raises InvalidSignatureError for invalid signatures' do
      # this script_pubkey is invalid for this transaction
      prev_tx = { bin_outputs: [ { amount: 100000000, script_pubkey: '76a914b4b69e5f4e517afcba6a42cffc0ccea72483c4b088ac' } ] }
      expect(subject).to receive(:list_transactions) { [ prev_tx ] }
      expect do
        subject.verify_signatures(hex)
      end.to raise_error Pochette::InvalidSignatureError
    end
  end

  describe '#pushtx' do
    it 'delegates to #_pushtx' do
      expect(subject).to receive(:_pushtx).with(hex)
      expect(subject.pushtx(hex)).to eq 'fb92420f73af6d25f5fab93435bc6b8ebfff3a07c02abd053f0923ae296fe380'
    end

    it 'verifies signatures' do
      expect(subject).to receive(:_pushtx).with(hex)
      expect(subject).to receive(:verify_signatures).with(hex, verify_signatures: true)
      subject.pushtx(hex, verify_signatures: true)
    end
  end
end
