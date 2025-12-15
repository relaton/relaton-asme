# frozen_string_literal: true

require "json"
require_relative "basic_page"

module RelatonAsme
  module Fetcher
    # Handles fetching ASME standards index via JSON API
    class IndexPage < BasicPage
      API_URL = "https://www.asme.org/api/products"
      DEFAULT_PER_PAGE = 100

      # Initialize index page for a specific page number
      #
      # @param page_number [Integer] Page number (1-based)
      # @param per_page [Integer] Results per page
      # @param agent [Mechanize, nil] Optional Mechanize agent
      def initialize(page_number: 1, per_page: DEFAULT_PER_PAGE, agent: nil)
        @page_number = page_number
        @per_page = per_page
        url = build_api_url(page_number, per_page)
        super(url, agent: agent)
      end

      # Extract publication URLs from the API response
      #
      # @return [Array<String>] Array of publication URLs
      def publication_urls
        ensure_page
        extract_urls_from_json
      end

      # Check if there are more pages
      #
      # @return [Boolean] True if more pages exist
      def more_pages?
        ensure_page
        data = parse_json_response
        return false unless data

        data["page"] < data["pages"]
      end

      private

      # Build the API URL with query parameters
      #
      # @param page_number [Integer] Page number
      # @param per_page [Integer] Results per page
      # @return [String] Full API URL
      def build_api_url(page_number, per_page)
        params = [
          "type=Codes-Standards",
          "page=#{page_number}",
          "perPage=#{per_page}",
          "sortBy=date",
          "sortByDir=desc"
        ].join("&")

        "#{API_URL}?#{params}"
      end

      # Parse JSON response from API
      #
      # @return [Hash, nil] Parsed JSON data or nil
      def parse_json_response
        JSON.parse(page.body)
      rescue JSON::ParserError => e
        warn "Failed to parse JSON response: #{e.message}"
        nil
      end

      # Extract publication URLs from JSON response
      #
      # @return [Array<String>] Publication URLs
      def extract_urls_from_json
        data = parse_json_response
        return [] unless data && data["results"]

        data["results"].map do |result|
          build_publication_urls(result)
        end.flatten.compact.uniq
      end

      # Build publication URLs from result data
      #
      # @param result [Hash] Result data from API
      # @return [Array<String>] URLs for the publication (one per edition)
      def build_publication_urls(result)
        base_url = extract_base_url(result)
        return [] unless base_url

        editions = extract_editions(result)
        formats = extract_formats(result)

        return [] if editions.empty? || formats.empty?

        preferred_format = select_preferred_format(formats)
        format_path = format_to_path(preferred_format)

        build_edition_urls(base_url, editions, format_path)
      end

      # Extract base URL from result
      #
      # @param result [Hash] Result data
      # @return [String, nil] Base URL or nil
      def extract_base_url(result)
        result.dig("WebsiteProductGrouping", "URL")
      end

      # Extract editions from result
      #
      # @param result [Hash] Result data
      # @return [Array<String>] Edition identifiers
      def extract_editions(result)
        result.dig("WebsiteProductGrouping", "Editions") || []
      end

      # Extract formats from result
      #
      # @param result [Hash] Result data
      # @return [Array<String>] Available formats
      def extract_formats(result)
        result.dig("WebsiteProductGrouping", "Formats") || []
      end

      # Select preferred format (PDF if available, otherwise first)
      #
      # @param formats [Array<String>] Available formats
      # @return [String] Preferred format
      def select_preferred_format(formats)
        formats.find { |f| f.downcase.include?("pdf") } || formats.first
      end

      # Build URLs for all editions
      #
      # @param base_url [String] Base URL
      # @param editions [Array<String>] Edition identifiers
      # @param format_path [String] Format path component
      # @return [Array<String>] Edition URLs
      def build_edition_urls(base_url, editions, format_path)
        editions.map do |edition|
          "https://www.asme.org#{base_url}/#{edition}/#{format_path}"
        end
      end

      # Convert format name to URL path component
      #
      # @param format [String] Format name
      # @return [String] URL path component
      def format_to_path(format)
        case format.downcase
        when /print.*book/
          "print-book"
        when /pdf/
          "pdf"
        when /bundle/
          "bundle"
        else
          format.downcase.tr(" ", "-")
        end
      end
    end
  end
end
