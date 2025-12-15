# frozen_string_literal: true

require "spec_helper"

RSpec.describe RelatonAsme::Fetcher::AsmeFormat do
  describe "initialization" do
    it "creates a format with all attributes" do
      format = described_class.new(
        format_type: "PDF",
        price: "$33.00",
        isbn: "9780791877005"
      )

      expect(format.format_type).to eq("PDF")
      expect(format.price).to eq("$33.00")
      expect(format.isbn).to eq("9780791877005")
    end

    it "allows nil for optional isbn" do
      format = described_class.new(
        format_type: "Print Book",
        price: "$675.00"
      )

      expect(format.format_type).to eq("Print Book")
      expect(format.price).to eq("$675.00")
      expect(format.isbn).to be_nil
    end
  end

  describe "JSON serialization" do
    it "serializes to JSON" do
      format = described_class.new(
        format_type: "PDF",
        price: "$33.00",
        isbn: "9780791877005"
      )

      json = format.to_json
      parsed = JSON.parse(json)

      expect(parsed["format_type"]).to eq("PDF")
      expect(parsed["price"]).to eq("$33.00")
      expect(parsed["isbn"]).to eq("9780791877005")
    end

    it "deserializes from JSON" do
      json = {
        format_type: "Bundle",
        price: "$750.00",
        isbn: "9780791877012"
      }.to_json

      format = described_class.from_json(json)

      expect(format.format_type).to eq("Bundle")
      expect(format.price).to eq("$750.00")
      expect(format.isbn).to eq("9780791877012")
    end
  end

  describe "YAML serialization" do
    it "serializes to YAML" do
      format = described_class.new(
        format_type: "Print Book",
        price: "$675.00"
      )

      yaml = format.to_yaml
      parsed = YAML.safe_load(
        yaml,
        permitted_classes: [described_class]
      )

      expect(parsed["format_type"]).to eq("Print Book")
      expect(parsed["price"]).to eq("$675.00")
    end

    it "deserializes from YAML" do
      yaml = <<~YAML
        format_type: PDF
        price: "$50.00"
        isbn: "1234567890"
      YAML

      format = described_class.from_yaml(yaml)

      expect(format.format_type).to eq("PDF")
      expect(format.price).to eq("$50.00")
      expect(format.isbn).to eq("1234567890")
    end
  end
end
