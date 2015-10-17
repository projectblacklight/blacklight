require 'spec_helper'

describe Blacklight do
  
  context 'root' do

    let(:blroot) { File.expand_path(File.join(__FILE__, '..', '..', '..' )) }

    it 'should return the full path to the BL plugin' do
      expect(Blacklight.root).to eq blroot
    end

  end
end
