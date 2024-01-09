# frozen_string_literal: true

require_relative 'request_state/base'
require_relative 'request_state/version'

module Bp3
  module RequestState
    class Error < StandardError; end
  end
end
