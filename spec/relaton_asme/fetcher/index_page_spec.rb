# frozen_string_literal: true

require "spec_helper"

RSpec.describe RelatonAsme::Fetcher::IndexPage do
  describe "initialization" do
    it "creates with default parameters" do
      page = described_class.new

      expect(page.url).to include("page=1")
      expect(page.url).to include("perPage=100")
      expect(page.url).to include("type=Codes-Standards")
    end

    it "creates with custom page number" do
      page = described_class.new(page_number: 3)

      expect(page.url).to include("page=3")
    end

    it "creates with custom per_page" do
      page = described_class.new(per_page: 50)

      expect(page.url).to include("perPage=50")
    end
  end

  describe "URL building" do
    it "builds correct API URL" do
      page = described_class.new

      expect(page.url).to start_with(
        "https://www.asme.org/api/products?"
      )
    end

    it "includes required query parameters" do
      page = described_class.new(page_number: 2, per_page: 25)

      expect(page.url).to include("type=Codes-Standards")
      expect(page.url).to include("page=2")
      expect(page.url).to include("perPage=25")
      expect(page.url).to include("sortBy=date")
      expect(page.url).to include("sortByDir=desc")
    end
  end

  describe "#publication_urls", :vcr do
    it "extracts publication URLs from API response" do
      page = described_class.new(page_number: 1, per_page: 5)
      urls = page.publication_urls

      expect(urls).to be_an(Array)
      if urls.any?
        urls.each do |url|
          expect(url).to start_with("https://www.asme.org/codes-standards")
        end
      end
    end

    it "returns unique URLs" do
      page = described_class.new(page_number: 1, per_page: 5)
      urls = page.publication_urls

      expect(urls.uniq).to eq(urls)
    end
  end

  describe "#more_pages?", :vcr do
    it "checks if more pages exist from API response" do
      page = described_class.new(page_number: 1, per_page: 10)

      result = page.more_pages?
      expect([true, false]).to include(result)
    end
  end
end
