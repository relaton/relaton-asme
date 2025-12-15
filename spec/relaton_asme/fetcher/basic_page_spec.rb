# frozen_string_literal: true

require "spec_helper"

RSpec.describe RelatonAsme::Fetcher::BasicPage do
  let(:test_url) { "https://www.asme.org/codes-standards" }

  describe "initialization" do
    it "creates a page with URL" do
      page = described_class.new(test_url)

      expect(page.url).to eq(test_url)
      expect(page.agent).to be_a(Mechanize)
      expect(page.page).to be_nil
    end

    it "accepts an existing agent" do
      existing_agent = Mechanize.new
      page = described_class.new(test_url, agent: existing_agent)

      expect(page.agent).to eq(existing_agent)
    end
  end

  describe "#fetch", :vcr do
    it "fetches the page" do
      page = described_class.new(test_url)
      result = page.fetch

      expect(result).to be_a(Mechanize::Page)
      expect(page.page).to eq(result)
    end
  end

  describe "#ensure_page", :vcr do
    it "fetches page if not already fetched" do
      page = described_class.new(test_url)
      result = page.ensure_page

      expect(result).to be_a(Mechanize::Page)
    end

    it "returns cached page if already fetched" do
      page = described_class.new(test_url)
      first_result = page.ensure_page
      second_result = page.ensure_page

      expect(second_result).to eq(first_result)
    end
  end

  describe "agent configuration" do
    it "configures agent with Safari user agent" do
      page = described_class.new(test_url)

      expect(page.agent.user_agent).to include("Safari")
      expect(page.agent.user_agent).to include("Mozilla")
    end

    it "enables meta refresh following" do
      page = described_class.new(test_url)

      expect(page.agent.follow_meta_refresh).to be true
    end

    it "enables redirects" do
      page = described_class.new(test_url)

      expect(page.agent.redirect_ok).to be true
    end
  end
end
