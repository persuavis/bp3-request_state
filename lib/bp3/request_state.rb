# frozen_string_literal: true

# require 'active_support/core_ext/module/attribute_accessors'
# require 'active_support/inflector'

require_relative 'request_state/base'
require_relative 'request_state/version'

module Bp3
  module RequestState
    class Error < StandardError; end
  end
end
