require 'spec_helper'

describe "Blacklight::Routes" do
  describe "default_route_sets" do
    around do |example|
      @original = Blacklight::Routes.default_route_sets.dup.freeze

      example.run

      Blacklight::Routes.default_route_sets = @original
    end

    it "is settable" do
      Blacklight::Routes.default_route_sets += [:foo]

      # Order DOES matter. 
      expect(Blacklight::Routes.default_route_sets).to eq(@original + [:foo])
    end
  end
end