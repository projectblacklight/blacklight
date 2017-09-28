require 'spec_helper'
require 'generators/blacklight/solr_generator'

RSpec.describe Blacklight::SolrGenerator do
  let(:destination) { Dir.mktmpdir }

  describe "#solr_wrapper_config" do
    let(:generator) { described_class.new }
    let(:files_to_test) {[
        File.join("#{destination}", '.solr_wrapper.yml')
    ]}

    before do
      generator.destination_root = destination
      generator.solr_wrapper_config

    end

    after do
      files_to_test.each { |file| File.delete(file) if File.exist?(file) }
    end

    it "creates config files" do
      files_to_test.each do |file|
        expect(File).to exist(file), "Expected #{file} to exist"
      end
    end
  end

  describe "#copy_solr_conf" do
    let(:generator) { described_class.new }
    let(:dirs_to_test) {[
        File.join("#{destination}", 'solr'),
        File.join("#{destination}", 'solr/conf')]}
    let(:files_to_test) {[
        File.join("#{destination}", 'solr/conf/solrconfig.xml')
    ]}

    before do
      generator.destination_root = destination
      generator.copy_solr_conf
    end

    after do
      dirs_to_test.each { |dir| FileUtils.rm_rf(Dir.glob(dir)) if File.directory?(dir) }
    end

    it "creates solr directory" do
      dirs_to_test.each do |dir|
        expect(File).to exist(dir), "Expected #{dir} to exist"
      end
    end

    it "copies solr config files" do
      files_to_test.each do |file|
        expect(File).to exist(file), "Expected #{file} to exist"
      end
    end
  end
end
