require 'spec_helper'

describe Pochette do
  it 'has a version number' do
    expect(Pochette::VERSION).not_to be nil
  end

  it 'has a global backend' do
    Pochette.backend.should be_nil
    Pochette.backend = 1
    Pochette.backend.should == 1
  end
end
