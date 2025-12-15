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
      # @return [Array<String>] URLs for each edition/format combination
      def build_publication_urls(result)
        base_url = result.dig("WebsiteProductGrouping", "URL")
        return [] unless base_url

        editions = result.dig("WebsiteProductGrouping", "Editions") || []
        formats = result.dig("WebsiteProductGrouping", "Formats") || []

        # Generate URLs for each edition/format combination
        urls = []
        editions.each do |edition|
          formats.each do |format|
            format_path = format_to_path(format)
            url = "https://www.asme.org#{base_url}/#{edition}/#{format_path}"
            urls << url
          end
        end

        urls
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
