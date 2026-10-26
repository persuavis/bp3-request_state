# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

bp3-request_state provides `Bp3::RequestState::Base`, the parent of BP3's `GlobalRequestState`. BP3
(persuavis/black_phoebe_3) is a multi-site multi-tenant Rails application, and the request state is how
every layer knows the current site, tenant, workspace and login without passing them around. bp3-core's
Tenantable default scopes, Rqid and the job wrappers in bp3-noticed are all built on this API.

## Commands

The gems run on Ruby 3.4.6 (`.ruby-version`). Prefix commands with `~/.rvm/bin/rvm 3.4.6 do` when the
shell is not already on it; a missing `rspec` means the wrong Ruby, not a missing bundle.

- `bundle exec rake` - specs and RuboCop (the default task)
- `bundle exec rspec spec/path/to/file_spec.rb[:LINE]` - one file or example
- `bundle exec rubocop` / `bundle exec rubocop -a`
- `bin/setup`, `bin/console`, `rake install`

## Architecture

`lib/bp3/request_state/base.rb`. Everything is class-level state in `RequestStore` under
`:bp3_request_state`, so it is per request (and per job, once the job sets it) and thread-safe.

**What a subclass declares**, then calls `define_accessors`:
- `hash_key_map`: state member to class name, used to load records back from ids
- `base_attrs`: the members; each gets a class getter and setter, an `_id` getter and setter, and an
  instance getter
- `hash_attrs`: the `_id` members `to_hash` serializes

**What the base provides**
- `current`, `clear!`, `request_id`, `started`, `duration`, `now`
- `to_hash` / `from_hash`: string-keyed hash of ids, request id, start time and locale, and back. This is
  how jobs carry the caller's state
- `either_site`, `either_tenant`, `either_workspace` (and `_id`): the `target_*` member if set, else
  `current_*`. `target_*` only exists in subclasses that declare it, as the application's does
- `either_admin`: `current_root || current_admin`
- `current_login`: `current_user || current_admin || current_root`, the least privileged login signed in.
  bp3-core decides how far default scopes reach from it
- `highest_privilege`: the reverse order. Neither includes `current_visitor`, who is not logged in
- `with_current(site:, tenant:, workspace:)`: clears and sets the state, then yields. It does not restore
  the previous state; the application's override does

`lib/bp3/request_state/test.rb` is a subclass with only `current_site` and `target_site`, backed by the
id-only stand-in `site.rb`. Neither is required by `lib/bp3/request_state.rb`; specs require them.

The application's `GlobalRequestState` (black_phoebe_3, `app/services/global_request_state.rb`) adds the
target members, `inbound_request`, and a `with_current` that restores the previous state; the README shows
it. A change to the names or semantics here reaches every bp3 gem that reads the state.

## Code Style

- RuboCop (`.rubocop.yml`): target Ruby 3.2.2, NewCops, rubocop-rake and rubocop-rspec
- Every file starts with `# frozen_string_literal: true`
- American English; no trailing whitespace on any added or modified line

## Release

Bump `lib/bp3/request_state/version.rb` and add a `CHANGELOG.md` entry. `rake release` tags, pushes and
publishes to rubygems.org; leave releasing and committing to the user.
