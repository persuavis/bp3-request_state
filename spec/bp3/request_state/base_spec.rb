# frozen_string_literal: true

require_relative '../../../lib/bp3/request_state/site'

RSpec.describe Bp3::RequestState::Base do
  after do
    described_class.clear!
  end

  before do
    described_class.class_eval('define_accessors', __FILE__, __LINE__)
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
    site = Bp3::RequestState::Site.new(11)
    expect(described_class.current_site).to be_nil
    described_class.current_site = site
    expect(described_class.current_site).to eq(site)
    expect(described_class.current_site_id).to eq(site.id)
    expect(described_class.to_hash['current_site_id']).to eq(site.id)
  end

  it 'supports setting by id' do
    site = Bp3::RequestState::Site.new(22)
    expect(described_class.current_site).to be_nil
    described_class.current_site_id = site.id
    expect(described_class.current_site).to eq(site)
    expect(described_class.current_site_id).to eq(site.id)
    expect(described_class.to_hash['current_site_id']).to eq(site.id)
  end
end
