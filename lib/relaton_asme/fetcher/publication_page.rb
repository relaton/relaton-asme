# frozen_string_literal: true

require "json"
require_relative "basic_page"
require_relative "asme_publication"
require_relative "asme_publication_edition"
require_relative "asme_format"

module RelatonAsme
  module Fetcher
    # Handles scraping of individual ASME publication pages
    class PublicationPage < BasicPage
      # Convert page data to AsmePublication model
      #
      # @return [AsmePublication, nil] Publication with editions or nil
      def to_data
        ensure_page
        jsonld_data = parse_jsonld

        return nil unless jsonld_data

        build_publication_from_jsonld(jsonld_data)
      end

      private

      # Parse JSON-LD structured data from page
      #
      # @return [Hash, nil] Parsed JSON-LD data or nil
      def parse_jsonld
        jsonld_script = page.search('script[type="application/ld+json"]').first
        return nil unless jsonld_script

        JSON.parse(jsonld_script.text)
      rescue JSON::ParserError => e
        warn "Failed to parse JSON-LD: #{e.message}"
        nil
      end

      # Build AsmePublication from JSON-LD data
      #
      # @param jsonld_data [Hash] JSON-LD data
      # @return [AsmePublication] Publication with editions
      def build_publication_from_jsonld(jsonld_data)
        offers = jsonld_data["offers"] || []
        base_title = jsonld_data["name"]
        designator = jsonld_data["sku"]

        # Group offers by year extracted from URL
        grouped_by_year = offers.group_by do |offer|
          extract_year_from_url(offer["url"])
        end

        # Remove entries with nil year
        grouped_by_year = grouped_by_year.reject { |year, _| year.nil? }

        # Create ONE edition per year with ALL formats
        editions = grouped_by_year.map do |year, year_offers|
          build_edition_from_offers(year_offers, base_title, designator, year)
        end.compact

        AsmePublication.new(
          publication_group: designator,
          editions: editions
        )
      end

      # Build edition from multiple offers for the same year
      #
      # @param offers [Array<Hash>] Offer data for the same year
      # @param base_title [String] Base publication title
      # @param designator [String] Publication designator/SKU
      # @param year [Integer] Edition year
      # @return [AsmePublicationEdition] Edition with all formats
      def build_edition_from_offers(offers, base_title, designator, year)
        first_offer = offers.first
        url = first_offer["url"]

        # Build title without designator prefix, just base title and year
        title = "#{base_title} (#{year})"
        document_identifier = "#{designator}-#{year}"

        # Collect ALL formats from ALL offers for this year
        formats = offers.map do |offer|
          format_type = extract_format_from_url(offer["url"])
          build_format_from_offer(offer, format_type)
        end.compact

        AsmePublicationEdition.new(
          url: url,
          document_type: "standard",
          title: title,
          document_identifier: document_identifier,
          designator: designator,
          edition_year: year.to_s,
          publisher: "ASME",
          publish_date: year.to_s,
          language: "EN",
          formats: formats
        )
      end

      # Extract year from URL
      #
      # @param url [String] URL
      # @return [Integer, nil] Year or nil
      def extract_year_from_url(url)
        match = url.match(%r{/(\d{4})/})
        match ? match[1].to_i : nil
      end

      # Extract format type from URL
      #
      # @param url [String] URL
      # @return [String] Format type
      def extract_format_from_url(url)
        return "PDF" if url.include?("/pdf")
        return "Print Book" if url.include?("/print")
        return "Bundle" if url.include?("/bundle")

        "PDF"
      end

      # Build format from offer data
      #
      # @param offer [Hash] Offer data
      # @param format_type [String] Format type
      # @return [AsmeFormat] Format object
      def build_format_from_offer(offer, format_type)
        price = offer["price"]
        price_str = format_price(price)

        AsmeFormat.new(
          format_type: format_type,
          price: price_str
        )
      end

      # Format price as currency string
      #
      # @param price [String, Numeric] Price value
      # @return [String] Formatted price
      def format_price(price)
        return nil unless price

        # Handle both string and numeric prices
        numeric_price = price.is_a?(String) ? price.to_f : price
        "$#{format('%.2f', numeric_price)}"
      end
    end
  end
end
