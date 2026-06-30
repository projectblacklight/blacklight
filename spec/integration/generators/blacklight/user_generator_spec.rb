# frozen_string_literal: true

require 'spec_helper'
require 'generators/blacklight/user_generator'

RSpec.describe Blacklight::UserGenerator do
  describe "#validate_authentication_options" do
    it "rejects multiple authentication providers" do
      generator = described_class.new(["user"], devise: true, authentication: true)

      expect { generator.validate_authentication_options }.to raise_error(Thor::Error, /either --devise or --authentication/)
    end
  end

  describe "#blacklight_user_display_key_configuration" do
    it "uses Rails authentication's email_address field when requested" do
      generator = described_class.new(["user"], authentication: true)

      expect(generator.send(:blacklight_user_display_key_configuration)).to eq "self.string_display_key = :email_address"
    end

    it "keeps the email configuration commented by default" do
      generator = described_class.new(["user"])

      expect(generator.send(:blacklight_user_display_key_configuration)).to eq "# self.string_display_key = :email"
    end
  end

  describe "#inject_rails_authentication_guest_transfer" do
    let(:destination) { Dir.mktmpdir }
    let(:generator) { described_class.new(["user"], authentication: true) }
    let(:sessions_path) { File.join(destination, "app/controllers/sessions_controller.rb") }

    before { generator.destination_root = destination }

    after { FileUtils.rm_rf(destination) }

    it "injects the guest transfer call after starting a session" do
      FileUtils.mkdir_p(File.dirname(sessions_path))
      File.write(sessions_path, <<~RUBY)
        class SessionsController < ApplicationController
          def create
            if user = User.authenticate_by(params.permit(:email_address, :password))
              start_new_session_for user
              redirect_to after_authentication_url
            end
          end
        end
      RUBY

      generator.send(:inject_rails_authentication_guest_transfer)

      expect(File.read(sessions_path)).to include("start_new_session_for user\n      transfer_guest_to_user\n")
    end

    it "is a no-op when there is no sessions controller" do
      expect { generator.send(:inject_rails_authentication_guest_transfer) }.not_to raise_error
    end
  end
end
