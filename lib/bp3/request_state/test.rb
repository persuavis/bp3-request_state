# frozen_string_literal: true

module Bp3
  module RequestState
    class Test < Base
      self.hash_key_map =
        {
          target_site: 'Bp3::RequestState::Site',
          current_site: 'Bp3::RequestState::Site'
        }.freeze

      self.base_attrs =
        %w[current_site target_site locale view_context].freeze

      self.hash_attrs = (base_attrs - %w[locale view_context]).map { |a| "#{a}_id" }

      define_accessors
    end
  end
end
