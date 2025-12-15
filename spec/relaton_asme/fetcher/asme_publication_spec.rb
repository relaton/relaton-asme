# frozen_string_literal: true

require "spec_helper"

RSpec.describe RelatonAsme::Fetcher::AsmePublication do
  let(:edition1) do
    RelatonAsme::Fetcher::AsmePublicationEdition.new(
      document_type: "standard",
      title: "BPVC.I-2025",
      document_identifier: "BPVC.I-2025",
      designator: "BPVC",
      edition_year: "2025",
      publisher: "ASME",
      publish_date: "2025",
      language: "EN"
    )
  end

  let(:edition2) do
    RelatonAsme::Fetcher::AsmePublicationEdition.new(
      document_type: "standard",
      title: "BPVC.I-2023",
      document_identifier: "BPVC.I-2023",
      designator: "BPVC",
      edition_year: "2023",
      publisher: "ASME",
      publish_date: "2023",
      language: "EN"
    )
  end

  describe "initialization" do
    it "creates a publication with editions" do
      publication = described_class.new(
        publication_group: "BPVC",
        editions: [edition1, edition2]
      )

      expect(publication.publication_group).to eq("BPVC")
      expect(publication.editions.size).to eq(2)
      expect(publication.editions).to include(edition1, edition2)
    end

    it "allows nil publication_group" do
      publication = described_class.new(
        editions: [edition1]
      )

      expect(publication.publication_group).to be_nil
      expect(publication.editions.size).to eq(1)
    end

    it "creates empty publication" do
      publication = described_class.new

      expect(publication.publication_group).to be_nil
      expect(publication.editions).to be_nil
    end
  end

  describe "JSON serialization" do
    it "serializes to JSON with all editions" do
      publication = described_class.new(
        publication_group: "BPVC",
        editions: [edition1, edition2]
      )

      json = publication.to_json
      parsed = JSON.parse(json)

      expect(parsed["publication_group"]).to eq("BPVC")
      expect(parsed["editions"]).to be_an(Array)
      expect(parsed["editions"].size).to eq(2)
      expect(parsed["editions"][0]["edition_year"]).to eq("2025")
      expect(parsed["editions"][1]["edition_year"]).to eq("2023")
    end

    it "deserializes from JSON" do
      json = {
        publication_group: "TEST",
        editions: [
          {
            document_type: "standard",
            title: "Test 2025",
            document_identifier: "T-2025",
            designator: "T",
            edition_year: "2025",
            publisher: "ASME",
            publish_date: "2025",
            language: "EN"
          }
        ]
      }.to_json

      publication = described_class.from_json(json)

      expect(publication.publication_group).to eq("TEST")
      expect(publication.editions.size).to eq(1)
      expect(publication.editions.first.edition_year).to eq("2025")
    end
  end

  describe "YAML serialization" do
    it "serializes to YAML" do
      publication = described_class.new(
        publication_group: "BPVC",
        editions: [edition1]
      )

      yaml = publication.to_yaml
      parsed = YAML.safe_load(
        yaml,
        permitted_classes: [
          described_class,
          RelatonAsme::Fetcher::AsmePublicationEdition,
          RelatonAsme::Fetcher::AsmeFormat
        ]
      )

      expect(parsed["publication_group"]).to eq("BPVC")
      expect(parsed["editions"]).to be_an(Array)
      expect(parsed["editions"].size).to eq(1)
    end

    it "deserializes from YAML" do
      yaml = <<~YAML
        publication_group: TEST
        editions:
          - document_type: standard
            title: Test 2025
            document_identifier: T-2025
            designator: T
            edition_year: "2025"
            publisher: ASME
            publish_date: "2025"
            language: EN
      YAML

      publication = described_class.from_yaml(yaml)

      expect(publication.publication_group).to eq("TEST")
      expect(publication.editions.size).to eq(1)
      expect(publication.editions.first.title).to eq("Test 2025")
    end
  end

  describe "editions collection" do
    it "handles multiple editions" do
      publication = described_class.new(
        editions: [edition1, edition2]
      )

      expect(publication.editions.size).to eq(2)
      years = publication.editions.map(&:edition_year)
      expect(years).to contain_exactly("2025", "2023")
    end

    it "handles single edition" do
      publication = described_class.new(
        editions: [edition1]
      )

      expect(publication.editions.size).to eq(1)
      expect(publication.editions.first).to eq(edition1)
    end
  end
end
