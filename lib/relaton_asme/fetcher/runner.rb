# frozen_string_literal: true

require_relative "index_page"
require_relative "publication_page"

module RelatonAsme
  module Fetcher
    # Orchestrates the fetching of ASME publications
    class Runner
      attr_reader :agent

      # Initialize the runner
      #
      # @param agent [Mechanize, nil] Optional Mechanize agent to reuse
      def initialize(agent: nil)
        @agent = agent || create_agent
      end

      # Fetch all publications from all pages
      #
      # @param max_pages [Integer, nil] Maximum pages to fetch (nil = all)
      # @param per_page [Integer] Results per page
      # @return [Array<AsmePublicationEdition>] All editions
      def fetch_all(max_pages: nil, per_page: 100)
        editions = []
        page_number = 1

        loop do
          puts "Fetching page #{page_number}..."
          page_editions = fetch_page(page_number, per_page: per_page)
          editions.concat(page_editions)

          break if max_pages && page_number >= max_pages
          break unless more_pages?(page_number, per_page)

          page_number += 1
        end

        deduplicate_editions(editions)
      end

      # Fetch publications from a specific page
      #
      # @param page_number [Integer] Page number to fetch
      # @param per_page [Integer] Results per page
      # @return [Array<AsmePublicationEdition>] Editions from the page
      def fetch_page(page_number, per_page: 100)
        index = IndexPage.new(
          page_number: page_number,
          per_page: per_page,
          agent: @agent
        )

        urls = index.publication_urls
        puts "Found #{urls.size} publications on page #{page_number}"

        fetch_publications(urls)
      end

      # Fetch multiple publications by URLs
      #
      # @param urls [Array<String>] Publication URLs
      # @return [Array<AsmePublicationEdition>] All editions
      def fetch_publications(urls)
        editions = []

        urls.each_with_index do |url, index|
          puts "Fetching publication #{index + 1}/#{urls.size}: #{url}"

          begin
            publication = fetch_publication(url)
            editions.concat(publication.editions) if publication&.editions
          rescue StandardError => e
            warn "Failed to fetch #{url}: #{e.message}"
          end
        end

        editions
      end

      # Fetch a single publication by URL
      #
      # @param url [String] Publication URL
      # @return [AsmePublication, nil] Publication with editions
      def fetch_publication(url)
        page = PublicationPage.new(url, agent: @agent)
        page.to_data
      end

      # Check if more pages exist
      #
      # @param page_number [Integer] Current page number
      # @param per_page [Integer] Results per page
      # @return [Boolean] True if more pages exist
      def more_pages?(page_number, per_page)
        index = IndexPage.new(
          page_number: page_number,
          per_page: per_page,
          agent: @agent
        )
        index.more_pages?
      end

      # Fetch all editions for publications and save to file
      #
      # @param output_file [String] Path to output file
      # @param format [Symbol] Output format (:json or :yaml)
      # @param max_pages [Integer, nil] Maximum pages to fetch
      # @return [Array<AsmePublicationEdition>] All editions
      def fetch_all_editions(output_file, format: :json, max_pages: nil)
        editions = fetch_all(max_pages: max_pages)

        save_editions(editions, output_file, format)

        editions
      end

      # Save editions to file
      #
      # @param editions [Array<AsmePublicationEdition>] Editions to save
      # @param output_file [String] Path to output file
      # @param format [Symbol] Output format (:json or :yaml)
      def save_editions(editions, output_file, format)
        content = case format
                  when :json
                    serialize_to_json(editions)
                  when :yaml
                    serialize_to_yaml(editions)
                  else
                    raise ArgumentError, "Unsupported format: #{format}"
                  end

        File.write(output_file, content)
        puts "Saved #{editions.size} editions to #{output_file}"
      end

      private

      # Create a new Mechanize agent
      #
      # @return [Mechanize] Configured agent
      def create_agent
        agent = Mechanize.new
        agent.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_2_1) " \
                           "AppleWebKit/605.1.15 (KHTML, like Gecko) " \
                           "Version/17.2 Safari/605.1.15"
        agent.follow_meta_refresh = true
        agent.redirect_ok = true
        agent
      end

      # Serialize editions to JSON
      #
      # @param editions [Array<AsmePublicationEdition>] Editions
      # @return [String] JSON string
      def serialize_to_json(editions)
        JSON.pretty_generate(editions.map(&:to_hash))
      end

      # Serialize editions to YAML
      #
      # @param editions [Array<AsmePublicationEdition>] Editions
      # @return [String] YAML string
      def serialize_to_yaml(editions)
        editions.map(&:to_hash).to_yaml
      end

      # Deduplicate editions by document_identifier
      # Merges formats from duplicates into single edition
      #
      # @param editions [Array<AsmePublicationEdition>] Editions to deduplicate
      # @return [Array<AsmePublicationEdition>] Deduplicated editions
      def deduplicate_editions(editions)
        grouped = editions.group_by(&:document_identifier)

        grouped.map do |identifier, group|
          next group.first if group.size == 1

          # Merge formats from duplicates (safety check)
          warn "Found #{group.size} duplicates for #{identifier}, merging..."
          merged_formats = group.flat_map(&:formats).uniq(&:format_type)

          first = group.first
          first.formats = merged_formats
          first
        end
      end
    end
  end
end
