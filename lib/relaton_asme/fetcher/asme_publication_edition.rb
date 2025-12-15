# frozen_string_literal: true

require "lutaml/model"
require_relative "asme_format"

module RelatonAsme
  module Fetcher
    # Represents a specific edition of an ASME publication
    # This is the PRIMARY data model containing all metadata
    class AsmePublicationEdition < Lutaml::Model::Serializable
      attribute :url, :string
      attribute :document_type, :string
      attribute :title, :string
      attribute :document_identifier, :string
      attribute :designator, :string
      attribute :edition_year, :string
      attribute :publisher, :string
      attribute :publish_date, :string
      attribute :language, :string
      attribute :number_of_pages, :integer
      attribute :description, :string
      attribute :topics, :string, collection: true
      attribute :formats, AsmeFormat, collection: true

      json do
        map "url", to: :url
        map "document_type", to: :document_type
        map "title", to: :title
        map "document_identifier", to: :document_identifier
        map "designator", to: :designator
        map "edition_year", to: :edition_year
        map "publisher", to: :publisher
        map "publish_date", to: :publish_date
        map "language", to: :language
        map "number_of_pages", to: :number_of_pages
        map "description", to: :description
        map "topics", to: :topics
        map "formats", to: :formats
      end

      yaml do
        map "url", to: :url
        map "document_type", to: :document_type
        map "title", to: :title
        map "document_identifier", to: :document_identifier
        map "designator", to: :designator
        map "edition_year", to: :edition_year
        map "publisher", to: :publisher
        map "publish_date", to: :publish_date
        map "language", to: :language
        map "number_of_pages", to: :number_of_pages
        map "description", to: :description
        map "topics", to: :topics
        map "formats", to: :formats
      end
    end
  end
end
