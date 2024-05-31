# frozen_string_literal: true

module Bp3
  module RequestState
    class Site
      attr_reader :id

      def initialize(id)
        @id = id
      end

      def self.find_by(id:)
        new(id)
      end

      def ==(other)
        id == other.id
      end
    end
  end
end
