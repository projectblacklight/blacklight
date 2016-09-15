require 'rails_helper'

describe <%= model_name.classify %> do
  let(:user_params) { Hash.new }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
  subject(:search_builder) { described_class.new scope }

  # describe "my custom step" do
  #   subject(:query_parameters) do
  #     search_builder.with(user_params).processed_parameters
  #   end
  #
  #   it "adds my custom data" do
  #     expect(query_parameters).to include :custom_data
  #   end
  # end
end