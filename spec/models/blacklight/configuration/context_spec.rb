# frozen_string_literal: true

RSpec.describe Blacklight::Configuration::Context, api: true do
  subject { described_class.new(context) }

  let(:context) { double }

  describe "#evaluate_configuration_conditional" do
    it "passes through regular values" do
      val = double
      expect(subject.evaluate_configuration_conditional(val)).to eq val
    end

    it "executes a helper method" do
      allow(context).to receive_messages(my_check: true)
      expect(subject.evaluate_configuration_conditional(:my_check)).to be true
    end

    it "calls a helper to determine if it should render a field" do
      a = double
      allow(context).to receive(:my_check_with_an_arg).with(a).and_return(true)
      expect(subject.evaluate_configuration_conditional(:my_check_with_an_arg, a)).to be true
    end

    it "evaluates a Proc to determine if it should render a field" do
      one_arg_lambda = ->(_context, _a) { true }
      two_arg_lambda = ->(_context, _a, _b) { true }
      expect(subject.evaluate_configuration_conditional(one_arg_lambda, 1)).to be true
      expect(subject.evaluate_configuration_conditional(two_arg_lambda, 1, 2)).to be true
    end
  end
end
