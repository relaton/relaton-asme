# frozen_string_literal: true

require "lutaml/model"
require_relative "asme_publication_edition"

module RelatonAsme
  module Fetcher
    # Container model for grouping related publication editions
    class AsmePublication < Lutaml::Model::Serializable
      attribute :publication_group, :string
      attribute :editions, AsmePublicationEdition, collection: true

      json do
        map "publication_group", to: :publication_group
        map "editions", to: :editions
      end

      yaml do
        map "publication_group", to: :publication_group
        map "editions", to: :editions
      end
    end
  end
end
