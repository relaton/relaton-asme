# frozen_string_literal: true

require "lutaml/model"

module RelatonAsme
  module Fetcher
    # Represents a publication format (e.g., PDF, Print Book, Bundle)
    class AsmeFormat < Lutaml::Model::Serializable
      attribute :format_type, :string
      attribute :price, :string
      attribute :isbn, :string

      json do
        map "format_type", to: :format_type
        map "price", to: :price
        map "isbn", to: :isbn
      end

      yaml do
        map "format_type", to: :format_type
        map "price", to: :price
        map "isbn", to: :isbn
      end
    end
  end
end
