# Bp3::RequestState

bp3-action_dispatch provides the `Bp3::RequestState::Base` class for BP3, the persuavis/black_phoebe_3
multi-site multi-tenant rails application.

`Bp3::RequestState::Base` can be used to store global state per request, or per background job. 
It keeps state per thread and is supposed to be thread safe.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bp3-request_state'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bp3-request_state

## Usage

In your app, create a model or service that inherits from `Bp3::Request::State`, and 
specify
- `hash_key_map`, mapping members of the global state to their class,
- `base_attrs`, defining the list of global state member objects, and
- `hash_attrs`, defining the list of members of the global state hash.
Override `.with_current` as needed.

Here is an example from BP3:
```ruby
class GlobalRequestState < Bp3::RequestState::Base
  self.hash_key_map =
    {
      target_site: 'Sites::Site',
      target_tenant: 'Tenant',
      target_workspace: 'Workspaces::Workspace',
      current_site: 'Sites::Site',
      current_tenant: 'Tenant',
      current_workspace: 'Workspaces::Workspace',
      current_user: 'Users::User',
      current_admin: 'Sites::Admin',
      current_root: 'Root',
      current_visitor: 'Users::Visitor'
    }.freeze

  self.base_attrs =
    %w[inbound_request
       current_site current_workspace current_tenant
       current_user current_admin current_root current_visitor
       target_site target_tenant target_workspace
       locale view_context].freeze

  self.hash_attrs = (base_attrs - %w[locale view_context]).map { |a| "#{a}_id" }

  define_accessors

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/ParameterLists
  def self.with_current(site:, tenant: nil, workspace: nil,
                        visitor: nil, login: nil,
                        request_id: nil, inbound_request: nil)
    # do NOT store the original in *RequestStore*, as it gets cleared after each request and each que job!!!
    Thread.current[:bp3_original_request_state] = current
    # super
    clear!
    self.request_id = request_id || inbound_request&.rqid
    self.inbound_request = inbound_request if inbound_request
    self.current_visitor = visitor
    self.current_site = site
    self.current_tenant = tenant || site.default_tenant
    self.current_workspace = workspace || site.default_workspace
    case login
    when Root
      self.current_root = login
    when Sites::Admin
      self.current_admin = login
    when Users::User
      self.current_user = login
    end
    yield if block_given?
  ensure
    RequestStore.write(:bp3_request_state, Thread.current[:bp3_original_request_state])
    Thread.current[:bp3_original_request_state] = nil
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/ParameterLists
end
```

You can then 
- set global state members: `GlobalRequestState.current_site = current_site`
- access the global state: `GlobalRequestState.current`
- get the global state hash: `GlobalRequestState.to_hash`
- reset the global state: `GlobalRequestState.clear!`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` 
to run the tests. You can also run `bin/console` for an interactive prompt that will allow 
you to experiment.

To install this gem onto your local machine, run `rake install`. To release a new version, 
update the version number in `version.rb`, and then run `rake release`, which will create 
a git tag for the version, push git commits and the created tag, and push the `.gem` file 
to [rubygems.org](https://rubygems.org).

## Testing
Run `rake` to run rspec tests and rubocop linting.

## Documentation
A `.yardopts` file is provided to support yard documentation.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
