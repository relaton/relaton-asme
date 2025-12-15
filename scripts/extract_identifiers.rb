#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

# Load the YAML data file
data_file = File.join(__dir__, "..", "data", "asme_publication_editions.yml")
editions = YAML.load_file(data_file, permitted_classes: [Symbol])

# Extract all document identifiers
identifiers = editions.map do |edition|
  edition["document_identifier"]
end.compact.sort

# Print statistics
puts "Total editions: #{editions.size}"
puts "Total identifiers: #{identifiers.size}"
puts "Unique identifiers: #{identifiers.uniq.size}"
puts "\n#{'=' * 80}"
puts "Document Identifiers (sorted):"
puts("=" * 80)

# Print all identifiers
identifiers.each do |identifier|
  puts identifier
end
