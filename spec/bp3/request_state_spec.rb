# frozen_string_literal: true

RSpec.describe Bp3::RequestState do
  it "has a version number" do
    expect(Bp3::RequestState::VERSION).not_to be nil
  end
end
