#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/relaton_asme"
require "fileutils"

puts "=" * 80
puts "RelatonAsme: Full Scrape of All ASME Publications"
puts "=" * 80
puts

# Create data directory
FileUtils.mkdir_p("data")

# Scrape all publications
runner = RelatonAsme::Fetcher::Runner.new

# Fetch all editions (no max_pages limit = fetch everything)
puts "Starting full scrape from ASME API..."
puts "This will fetch all 671 publications from API and parse their JSON-LD data"
puts

editions = runner.fetch_all_editions(
  "data/asme_publication_editions.yml",
  format: :yaml,
  max_pages: 10  # Start with 10 pages for testing, remove to fetch all
)

puts "\n" + "=" * 80
puts "Scrape Complete!"
puts "=" * 80
puts "Total editions saved: #{editions.size}"
puts "Output file: data/asme_publication_editions.yml"
puts "File size: #{File.size('data/asme_publication_editions.yml')} bytes"
puts "=" * 80