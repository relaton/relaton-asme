# frozen_string_literal: true

require_relative "relaton_asme/version"
require_relative "relaton_asme/fetcher/asme_format"
require_relative "relaton_asme/fetcher/asme_publication_edition"
require_relative "relaton_asme/fetcher/asme_publication"
require_relative "relaton_asme/fetcher/basic_page"
require_relative "relaton_asme/fetcher/index_page"
require_relative "relaton_asme/fetcher/publication_page"
require_relative "relaton_asme/fetcher/runner"

module RelatonAsme
  class Error < StandardError; end
end
