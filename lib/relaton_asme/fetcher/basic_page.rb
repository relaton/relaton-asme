# frozen_string_literal: true

require "mechanize"

module RelatonAsme
  module Fetcher
    # Base class for web scraping pages using Mechanize
    class BasicPage
      attr_reader :url, :page, :agent

      # Initialize a new page fetcher
      #
      # @param url [String] URL to fetch
      # @param agent [Mechanize, nil] Optional Mechanize agent to reuse
      def initialize(url, agent: nil)
        @url = url
        @agent = agent || create_agent
        @page = nil
      end

      # Fetch the page
      #
      # @return [Mechanize::Page] The fetched page
      def fetch
        @page = @agent.get(url)
      end

      # Get the page, fetching if necessary
      #
      # @return [Mechanize::Page] The page
      def ensure_page
        @ensure_page ||= fetch
      end

      private

      # Create a new Mechanize agent with standard configuration
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
    end
  end
end
