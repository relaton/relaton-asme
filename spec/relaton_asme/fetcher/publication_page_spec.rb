# frozen_string_literal: true

require "spec_helper"

RSpec.describe RelatonAsme::Fetcher::PublicationPage do
  let(:test_url) do
    "https://www.asme.org/codes-standards/find-codes-standards/" \
      "temperature-measurement/2024/pdf"
  end

  describe "#to_data", :vcr do
    it "extracts publication data from JSON-LD" do
      page = described_class.new(test_url)
      publication = page.to_data

      if publication
        expect(publication).to be_a(
          RelatonAsme::Fetcher::AsmePublication
        )
        expect(publication.editions).to be_an(Array)
        expect(publication.editions).not_to be_empty
      else
        expect(publication).to be_nil
      end
    end

    it "extracts edition attributes from JSON-LD" do
      page = described_class.new(test_url)
      publication = page.to_data

      if publication&.editions&.any?
        edition = publication.editions.first
        expect(edition).to be_a(
          RelatonAsme::Fetcher::AsmePublicationEdition
        )
        expect(edition.url).not_to be_nil
        expect(edition.document_identifier).not_to be_nil
        expect(edition.designator).not_to be_nil
        expect(edition.edition_year).to be_a(String)
        expect(edition.title).not_to start_with(edition.designator)
      end
    end
  end

  describe "URL extraction" do
    let(:page) { described_class.new(test_url) }

    it "extracts year from URL" do
      url = "https://www.asme.org/test/2024/pdf/"
      result = page.send(:extract_year_from_url, url)
      expect(result).to eq(2024)
    end

    it "returns nil for URL without year" do
      url = "https://www.asme.org/test"
      result = page.send(:extract_year_from_url, url)
      expect(result).to be_nil
    end

    it "extracts format from PDF URL" do
      url = "https://www.asme.org/test/2024/pdf/"
      result = page.send(:extract_format_from_url, url)
      expect(result).to eq("PDF")
    end

    it "extracts format from print book URL" do
      url = "https://www.asme.org/test/2024/print-book/"
      result = page.send(:extract_format_from_url, url)
      expect(result).to eq("Print Book")
    end

    it "defaults to PDF for unknown format" do
      url = "https://www.asme.org/test/2024/unknown/"
      result = page.send(:extract_format_from_url, url)
      expect(result).to eq("PDF")
    end
  end

  describe "#build_format_from_offer" do
    let(:page) { described_class.new(test_url) }

    it "builds format from offer data" do
      offer = {
        "price" => 125,
        "priceCurrency" => "USD"
      }

      format = page.send(:build_format_from_offer, offer, "PDF")

      expect(format).to be_a(RelatonAsme::Fetcher::AsmeFormat)
      expect(format.format_type).to eq("PDF")
      expect(format.price).to eq("$125.00")
    end

    it "defaults to USD currency" do
      offer = { "price" => 100 }

      format = page.send(:build_format_from_offer, offer, "Print Book")

      expect(format.price).to eq("$100.00")
    end
  end

  describe "#build_edition_from_offers" do
    let(:page) { described_class.new(test_url) }

    it "builds edition from multiple offers for same year" do
      offers = [
        {
          "url" => "https://www.asme.org/test/2024/pdf/",
          "price" => 125,
          "priceCurrency" => "USD"
        },
        {
          "url" => "https://www.asme.org/test/2024/print-book/",
          "price" => 200,
          "priceCurrency" => "USD"
        },
        {
          "url" => "https://www.asme.org/test/2024/bundle/",
          "price" => 300,
          "priceCurrency" => "USD"
        }
      ]

      edition = page.send(
        :build_edition_from_offers,
        offers,
        "Test Standard",
        "TEST",
        2024
      )

      expect(edition).to be_a(
        RelatonAsme::Fetcher::AsmePublicationEdition
      )
      expect(edition.url).to eq(
        "https://www.asme.org/test/2024/pdf/"
      )
      expect(edition.title).to eq("Test Standard (2024)")
      expect(edition.title).not_to start_with("TEST")
      expect(edition.document_identifier).to eq("TEST-2024")
      expect(edition.designator).to eq("TEST")
      expect(edition.edition_year).to eq("2024")
      expect(edition.formats.size).to eq(3)
      expect(edition.formats.map(&:format_type))
        .to include("PDF", "Print Book", "Bundle")
    end

    it "builds edition from single offer" do
      offers = [
        {
          "url" => "https://www.asme.org/test/2024/pdf/",
          "price" => 125,
          "priceCurrency" => "USD"
        }
      ]

      edition = page.send(
        :build_edition_from_offers,
        offers,
        "Test Standard",
        "TEST",
        2024
      )

      expect(edition).to be_a(
        RelatonAsme::Fetcher::AsmePublicationEdition
      )
      expect(edition.formats.size).to eq(1)
      expect(edition.formats.first.format_type).to eq("PDF")
    end
  end
end
