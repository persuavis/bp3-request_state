# frozen_string_literal: true

require_relative '../../../lib/bp3/request_state/test'
require_relative '../../../lib/bp3/request_state/site'

RSpec.describe Bp3::RequestState::Test do
  after do
    described_class.clear!
  end

  let(:site) { Bp3::RequestState::Site.new(123) }

  it 'stores the site' do
    described_class.current_site = site
    expect(described_class.current_site).to eq(site)
    expect(described_class.new.current_site).to eq(site)
    expect(described_class.to_hash['current_site_id']).to eq(site.id)
  end

  it 'stores the locale' do
    described_class.locale = :nl
    expect(described_class.locale).to eq(:nl)
    expect(described_class.new.locale).to eq(:nl)
    expect(described_class.to_hash['locale']).to eq('nl')
  end

  it 'provides a context hash' do
    described_class.current_site = site
    Time.freeze do
      hash = described_class.to_hash
      expect(hash['current_site_id']).to eq(site.id)
      expect(hash['started_string']).to eq(DateTime.current.to_s)
    end
  end

  it 'loads a context hash' do
    time = DateTime.current
    hash = {
      current_site_id: site.id,
      started_string: time.to_s
    }
    state = described_class.from_hash(hash)
    expect(state.current_site.id).to eq(site.id)
    expect(state.started.to_s).to eq(time.to_s)
  end

  it 'has various setters and getters' do
    site = Bp3::RequestState::Site.new(1)
    expect(described_class.current_site).to be_nil
    described_class.current_site = site
    expect(described_class.current_site).to eq(site)
    expect(described_class.current_site_id).to eq(site.id)
    expect(described_class.to_hash['current_site_id']).to eq(site.id)
  end

  it 'supports setting by id' do
    site = Bp3::RequestState::Site.new(2)
    expect(described_class.current_site).to be_nil
    described_class.current_site_id = site.id
    expect(described_class.current_site).to eq(site)
    expect(described_class.current_site_id).to eq(site.id)
    expect(described_class.to_hash['current_site_id']).to eq(site.id)
  end

  it 'supports #target_site' do
    site = Bp3::RequestState::Site.new(3)
    expect(described_class.target_site).to be_nil
    described_class.target_site_id = site.id
    expect(described_class.target_site).to eq(site)
    expect(described_class.target_site_id).to eq(site.id)
    expect(described_class.to_hash['target_site_id']).to eq(site.id)
  end

  it 'supports #eiter_site' do
    current_site = Bp3::RequestState::Site.new(5)
    target_site = Bp3::RequestState::Site.new(7)
    described_class.current_site_id = current_site.id
    described_class.target_site_id = target_site.id
    expect(described_class.either_site).to eq(target_site)
    expect(described_class.either_site_id).to eq(target_site.id)
    expect(described_class.to_hash['either_site_id']).to be_nil # not included in hash
  end
end
