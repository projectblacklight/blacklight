# frozen_string_literal: true

RSpec.describe "Search History Page" do

  describe "crawler search" do
    let(:original_proc) { ::CatalogController.blacklight_config.crawler_detector }

    before do
      ::CatalogController.blacklight_config.crawler_detector = lambda { |req| req.env['HTTP_USER_AGENT'] =~ /Googlebot/ }
    end

    after do
      ::CatalogController.blacklight_config.crawler_detector = original_proc
    end

    it "remembers human searches" do
      visit root_path
      fill_in "q", with: 'chicken'
      expect { click_button 'search' }.to change { Search.count }.by(1)
    end

    it "doesn't remember bot searches" do
      page.driver.header('User-Agent', 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)')
      visit root_path
      fill_in "q", with: 'chicken'
      expect { click_button 'search' }.to_not change { Search.count }
    end
  end

end
