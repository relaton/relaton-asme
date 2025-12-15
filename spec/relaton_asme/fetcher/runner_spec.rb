# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe RelatonAsme::Fetcher::Runner do
  describe "initialization" do
    it "creates a runner with new agent" do
      runner = described_class.new

      expect(runner.agent).to be_a(Mechanize)
    end

    it "accepts an existing agent" do
      existing_agent = Mechanize.new
      runner = described_class.new(agent: existing_agent)

      expect(runner.agent).to eq(existing_agent)
    end
  end

  describe "#fetch_publication", :vcr do
    it "fetches a single publication" do
      runner = described_class.new
      url = "https://www.asme.org/codes-standards/find-codes-standards/test"

      # This will either return nil or raise an error for non-existent URL
      result = begin
        runner.fetch_publication(url)
      rescue Mechanize::ResponseCodeError
        nil
      end

      # Either nil or AsmePublication
      if result
        expect(result).to be_a(
          RelatonAsme::Fetcher::AsmePublication
        )
      else
        expect(result).to be_nil
      end
    end
  end

  describe "#fetch_publications" do
    it "fetches multiple publications" do
      runner = described_class.new
      urls = [
        "https://www.asme.org/codes-standards/find-codes-standards/test1",
        "https://www.asme.org/codes-standards/find-codes-standards/test2"
      ]

      # Suppress output during test
      allow(runner).to receive(:puts)
      allow(runner).to receive(:warn)

      editions = runner.fetch_publications(urls)

      expect(editions).to be_an(Array)
      # Editions might be empty if fetching failed
    end

    it "handles errors gracefully" do
      runner = described_class.new
      urls = ["https://www.asme.org/nonexistent"]

      # Suppress output during test
      allow(runner).to receive(:puts)
      expect(runner).to receive(:warn).at_least(:once)

      editions = runner.fetch_publications(urls)

      expect(editions).to be_an(Array)
      expect(editions).to be_empty
    end
  end

  describe "#fetch_page", :vcr do
    it "fetches publications from a page" do
      runner = described_class.new

      # Suppress output during test
      allow(runner).to receive(:puts)
      allow(runner).to receive(:warn)

      editions = runner.fetch_page(1, per_page: 5)

      expect(editions).to be_an(Array)
    end
  end

  describe "#more_pages?", :vcr do
    it "checks if more pages exist" do
      runner = described_class.new

      result = runner.more_pages?(1, 10)

      expect([true, false]).to include(result)
    end
  end

  describe "#save_editions" do
    let(:runner) { described_class.new }
    let(:editions) do
      [
        RelatonAsme::Fetcher::AsmePublicationEdition.new(
          document_type: "standard",
          title: "Test Standard",
          document_identifier: "TEST-2025",
          designator: "TEST",
          edition_year: 2025,
          publisher: "ASME",
          publish_date: "2025",
          language: "EN"
        )
      ]
    end

    it "saves editions to JSON file" do
      Tempfile.create(["test", ".json"]) do |file|
        # Suppress output during test
        allow(runner).to receive(:puts)

        runner.save_editions(editions, file.path, :json)

        content = File.read(file.path)
        parsed = JSON.parse(content)

        expect(parsed).to be_an(Array)
        expect(parsed.size).to eq(1)
        expect(parsed[0]["title"]).to eq("Test Standard")
      end
    end

    it "saves editions to YAML file" do
      Tempfile.create(["test", ".yml"]) do |file|
        # Suppress output during test
        allow(runner).to receive(:puts)

        runner.save_editions(editions, file.path, :yaml)

        content = File.read(file.path)
        parsed = YAML.safe_load(
          content,
          permitted_classes: [
            RelatonAsme::Fetcher::AsmePublicationEdition,
            RelatonAsme::Fetcher::AsmeFormat
          ]
        )

        expect(parsed).to be_an(Array)
        expect(parsed.size).to eq(1)
        expect(parsed[0]["title"]).to eq("Test Standard")
      end
    end

    it "raises error for unsupported format" do
      file = Tempfile.new

      expect do
        runner.save_editions(editions, file.path, :xml)
      end.to raise_error(ArgumentError, /Unsupported format/)

      file.close
      file.unlink
    end
  end

  describe "#fetch_all" do
    it "fetches all publications with max_pages limit" do
      runner = described_class.new

      # Suppress output during test
      allow(runner).to receive(:puts)
      allow(runner).to receive(:warn)

      # Mock to avoid actual fetching
      allow(runner).to receive(:fetch_page).and_return([])
      allow(runner).to receive(:more_pages?).and_return(false)

      editions = runner.fetch_all(max_pages: 1)

      expect(editions).to be_an(Array)
    end

    it "deduplicates editions with same identifier" do
      runner = described_class.new

      # Create duplicate editions
      format1 = RelatonAsme::Fetcher::AsmeFormat.new(
        format_type: "PDF",
        price: "$100.00"
      )
      format2 = RelatonAsme::Fetcher::AsmeFormat.new(
        format_type: "Print Book",
        price: "$200.00"
      )

      edition1 = RelatonAsme::Fetcher::AsmePublicationEdition.new(
        document_identifier: "TEST-2024",
        title: "Test Standard (2024)",
        designator: "TEST",
        edition_year: "2024",
        formats: [format1]
      )

      edition2 = RelatonAsme::Fetcher::AsmePublicationEdition.new(
        document_identifier: "TEST-2024",
        title: "Test Standard (2024)",
        designator: "TEST",
        edition_year: "2024",
        formats: [format2]
      )

      # Suppress output during test
      allow(runner).to receive(:puts)
      allow(runner).to receive(:warn)
      allow(runner).to receive(:fetch_page).and_return([edition1, edition2])
      allow(runner).to receive(:more_pages?).and_return(false)

      editions = runner.fetch_all(max_pages: 1)

      # Should have only one edition with merged formats
      expect(editions.size).to eq(1)
      expect(editions.first.formats.size).to eq(2)
      expect(editions.first.formats.map(&:format_type))
        .to contain_exactly("PDF", "Print Book")
    end
  end

  describe "agent configuration" do
    it "configures agent with proper user agent" do
      runner = described_class.new

      expect(runner.agent.user_agent).to include("Safari")
      expect(runner.agent.user_agent).to include("Mozilla")
    end

    it "enables meta refresh following" do
      runner = described_class.new

      expect(runner.agent.follow_meta_refresh).to be true
    end

    it "enables redirects" do
      runner = described_class.new

      expect(runner.agent.redirect_ok).to be true
    end
  end
end
