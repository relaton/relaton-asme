# frozen_string_literal: true

require "spec_helper"

RSpec.describe RelatonAsme::Fetcher::AsmePublicationEdition do
  let(:format1) do
    RelatonAsme::Fetcher::AsmeFormat.new(
      format_type: "PDF",
      price: "$33.00"
    )
  end

  let(:format2) do
    RelatonAsme::Fetcher::AsmeFormat.new(
      format_type: "Print Book",
      price: "$675.00",
      isbn: "9780791877005"
    )
  end

  describe "initialization" do
    it "creates an edition with all attributes" do
      edition = described_class.new(
        document_type: "standard",
        title: "ASME Orientation and Guide",
        document_identifier: "SI-1-1982",
        designator: "SI-1",
        edition_year: "1982",
        publisher: "ASME",
        publish_date: "1982",
        language: "EN",
        number_of_pages: 36,
        description: "This booklet includes: SI Base Units",
        topics: ["Advanced Manufacturing"],
        formats: [format1, format2]
      )

      expect(edition.document_type).to eq("standard")
      expect(edition.title).to eq("ASME Orientation and Guide")
      expect(edition.document_identifier).to eq("SI-1-1982")
      expect(edition.designator).to eq("SI-1")
      expect(edition.edition_year).to eq("1982")
      expect(edition.publisher).to eq("ASME")
      expect(edition.publish_date).to eq("1982")
      expect(edition.language).to eq("EN")
      expect(edition.number_of_pages).to eq(36)
      expect(edition.description).to eq("This booklet includes: SI Base Units")
      expect(edition.topics).to eq(["Advanced Manufacturing"])
      expect(edition.formats).to eq([format1, format2])
    end

    it "allows nil for optional fields" do
      edition = described_class.new(
        document_type: "standard",
        title: "Test Standard",
        document_identifier: "TEST-2025",
        designator: "TEST",
        edition_year: "2025",
        publisher: "ASME",
        publish_date: "2025",
        language: "EN"
      )

      expect(edition.number_of_pages).to be_nil
      expect(edition.description).to be_nil
      expect(edition.topics).to be_nil
      expect(edition.formats).to be_nil
    end
  end

  describe "JSON serialization" do
    it "serializes to JSON with all attributes" do
      edition = described_class.new(
        document_type: "standard",
        title: "Test Standard",
        document_identifier: "TEST-2025",
        designator: "TEST",
        edition_year: "2025",
        publisher: "ASME",
        publish_date: "2025",
        language: "EN",
        number_of_pages: 100,
        description: "Test description",
        topics: %w[Topic1 Topic2],
        formats: [format1]
      )

      json = edition.to_json
      parsed = JSON.parse(json)

      expect(parsed["document_type"]).to eq("standard")
      expect(parsed["title"]).to eq("Test Standard")
      expect(parsed["edition_year"]).to eq("2025")
      expect(parsed["number_of_pages"]).to eq(100)
      expect(parsed["topics"]).to eq(%w[Topic1 Topic2])
      expect(parsed["formats"]).to be_an(Array)
      expect(parsed["formats"].size).to eq(1)
    end

    it "deserializes from JSON" do
      json = {
        document_type: "standard",
        title: "Test",
        document_identifier: "T-1",
        designator: "T",
        edition_year: "2023",
        publisher: "ASME",
        publish_date: "2023",
        language: "EN",
        formats: [
          { format_type: "PDF", price: "$50.00" }
        ]
      }.to_json

      edition = described_class.from_json(json)

      expect(edition.document_type).to eq("standard")
      expect(edition.edition_year).to eq("2023")
      expect(edition.formats.size).to eq(1)
      expect(edition.formats.first.format_type).to eq("PDF")
    end
  end

  describe "YAML serialization" do
    it "serializes to YAML" do
      edition = described_class.new(
        document_type: "standard",
        title: "Test",
        document_identifier: "T-1",
        designator: "T",
        edition_year: "2023",
        publisher: "ASME",
        publish_date: "2023",
        language: "EN",
        topics: ["Topic1"]
      )

      yaml = edition.to_yaml
      parsed = YAML.safe_load(
        yaml,
        permitted_classes: [
          described_class,
          RelatonAsme::Fetcher::AsmeFormat
        ]
      )

      expect(parsed["document_type"]).to eq("standard")
      expect(parsed["edition_year"]).to eq("2023")
      expect(parsed["topics"]).to eq(["Topic1"])
    end

    it "deserializes from YAML" do
      yaml = <<~YAML
        document_type: standard
        title: Test Standard
        document_identifier: TEST-2025
        designator: TEST
        edition_year: "2025"
        publisher: ASME
        publish_date: "2025"
        language: EN
        number_of_pages: 50
      YAML

      edition = described_class.from_yaml(yaml)

      expect(edition.document_type).to eq("standard")
      expect(edition.title).to eq("Test Standard")
      expect(edition.edition_year).to eq("2025")
      expect(edition.number_of_pages).to eq(50)
    end
  end

  describe "collections" do
    it "handles multiple topics" do
      edition = described_class.new(
        document_type: "standard",
        title: "Test",
        document_identifier: "T-1",
        designator: "T",
        edition_year: "2025",
        publisher: "ASME",
        publish_date: "2025",
        language: "EN",
        topics: %w[Topic1 Topic2 Topic3]
      )

      expect(edition.topics.size).to eq(3)
      expect(edition.topics).to include("Topic1", "Topic2", "Topic3")
    end

    it "handles multiple formats" do
      edition = described_class.new(
        document_type: "standard",
        title: "Test",
        document_identifier: "T-1",
        designator: "T",
        edition_year: "2025",
        publisher: "ASME",
        publish_date: "2025",
        language: "EN",
        formats: [format1, format2]
      )

      expect(edition.formats.size).to eq(2)
      expect(edition.formats.first.format_type).to eq("PDF")
      expect(edition.formats.last.format_type).to eq("Print Book")
    end
  end
end
