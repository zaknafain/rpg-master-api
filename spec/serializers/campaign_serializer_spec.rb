# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CampaignSerializer do
  let(:serialized_campaign) do
    described_class.new(campaign, scope: user, scope_name: :current_user)
  end
  let(:campaign) { FactoryBot.create(:campaign) }
  let(:user)     { FactoryBot.create(:user) }

  it 'does not throw an error' do
    expect { serialized_campaign.serializable_hash }.not_to raise_error
  end
end
