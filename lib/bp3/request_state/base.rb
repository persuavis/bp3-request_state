# frozen_string_literal: true

require 'request_store'
require 'active_support'
require 'active_support/core_ext/date'
require 'active_support/core_ext/time'
require 'active_support/core_ext/date_time'
require 'active_support/core_ext/object'
require 'forwardable'
require 'ostruct'

module Bp3
  module RequestState
    # rubocop:disable Metrics/ClassLength
    class Base
      extend Forwardable

      HASH_KEY_MAP =
        { current_site: 'Bp3::RequestState::Site',
          current_tenant: 'Tenant',
          current_workspace: 'Workspace',
          current_user: 'User' }.freeze

      ALL_ATTRS =
        %w[request_id current_site current_tenant current_workspace current_user locale view_context].freeze

      ID_ATTRS =
        %w[current_site_id current_tenant_id current_workspace_id current_user_id].freeze

      def self.clear!
        RequestStore.delete(:bp3_request_state)
      end

      def self.current
        RequestStore.fetch(:bp3_request_state) do
          { started: DateTime.current }
        end
      end

      def self.with_current(site:, tenant: nil, workspace: nil)
        clear!
        self.current_site = site
        self.current_tenant = tenant || site.default_tenant # TODO
        self.current_workspace = workspace || site.default_workspace
        yield if block_given?
      end

      def self.to_hash
        {
          request_id:,
          started_string: started.utc.to_s,
          locale: locale&.to_s
        }.tap do |hash|
          self::ID_ATTRS.each do |id_attr|
            attr = id_attr.gsub('_id', '')
            hash[id_attr] = send(id_attr) if respond_to?(attr)
          end
        end.stringify_keys
      end

      def self.define_accessors(attrs)
        attrs.each do |attr|
          define_accessors_for_one_attr(attr)
        end

        # current_login picks one of the logged-in user, site-admin or root.
        # pick the one with least privileges first
        define_singleton_method :current_login do
          current_user || current_admin || current_root
        end
        define_method :current_login do
          current_user || current_admin || current_root
        end

        define_singleton_method :highest_privilege do
          # do not include current_visitor, as they are not logged in
          current_root || current_admin || current_user # || current_visitor
        end
        define_method :highest_privilege do
          # do not include current_visitor, as they are not logged in
          current_root || current_admin || current_user # || current_visitor
        end
      end

      def self.from_hash(hash)
        state = OpenStruct.new(hash) # rubocop:disable Style/OpenStructUse
        fill_from_map(state)
        fill_details(state)
        self
      end

      def self.fill_from_map(state)
        HASH_KEY_MAP.each_key do |attr|
          with_id = "#{attr}_id"
          fill_one_from_map(attr.to_sym, state.send(with_id)) if state.send(with_id)
        end
      end

      def self.fill_one_from_map(attr, id)
        klass = self::HASH_KEY_MAP[attr.to_sym]&.constantize
        writer = "#{attr}="
        send(writer, klass.find_by(id:))
      end

      def self.fill_details(state)
        self.request_id = state.request_id if state.request_id
        self.started = state.started_string.present? ? DateTime.parse(state.started_string) : nil
        self.locale = state.locale&.to_sym
      end

      def self.either_site
        target_site || current_site
      end
      def_delegator self, :either_site

      def self.either_site_id
        target_site_id || current_site_id
      end

      def self.either_tenant
        target_tenant || current_tenant
      end
      def_delegator self, :either_tenant

      def self.either_tenant_id
        target_tenant_id || current_tenant_id
      end

      def self.either_workspace
        target_workspace || current_workspace
      end
      def_delegator self, :either_workspace

      def self.either_workspace_id
        target_workspace_id || current_workspace_id
      end

      def self.either_admin
        current_root || current_admin
      end
      def_delegator self, :either_admin

      def self.duration
        (now - started) * 1.day # in seconds
      end
      def_delegator self, :duration

      def self.now
        DateTime.current
      end
      def_delegator self, :now

      def self.started
        current[:started] || now
      end
      def_delegator self, :started

      def self.started=(time)
        current[:started] = time || now
      end

      def self.define_accessors_for_one_attr(attr)
        define_getter(attr)
        define_setter(attr)
        define_id_getter(attr)
        define_id_setter(attr)
        define_method(attr) do
          self.class.current[attr.to_sym]
        end
      end

      def self.define_getter(attr)
        define_singleton_method(attr) do
          current[attr.to_sym]
        end
      end

      def self.define_setter(attr)
        define_singleton_method("#{attr}=") do |obj|
          current[attr.to_sym] = obj
        end
      end

      def self.define_id_getter(attr)
        define_singleton_method("#{attr}_id") do
          current[attr.to_sym]&.id
        end
      end

      def self.define_id_setter(attr)
        define_singleton_method("#{attr}_id=") do |id|
          current[attr.to_sym] = fill_one_from_map(attr.to_sym, id)
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
