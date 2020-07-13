# frozen_string_literal: true

require 'rails_helper'

describe Campaign do
  let(:element)  { FactoryBot.create(:hierarchy_element) }
  let(:campaign) { element.hierarchable }
  let(:player)   { FactoryBot.create(:user) }

  before do
    player.campaigns_played << campaign
  end

  describe 'all_campaigns_for user' do
    let!(:campaign_2) { FactoryBot.create(:campaign, user: player) }
    let!(:campaign_3) { FactoryBot.create(:campaign) }

    it 'will show owned and played campaigns' do
      expect(
        described_class.all_campaigns_for(player.id)
      ).to include(campaign)
      expect(
        described_class.all_campaigns_for(player.id)
      ).to include(campaign_2)
      expect(
        described_class.all_campaigns_for(player.id)
      ).not_to include(campaign_3)
    end

    it 'will show only owned campaigns if there are no played' do
      user = campaign.user

      expect(
        described_class.all_campaigns_for(user.id)
      ).to include(campaign)
      expect(
        described_class.all_campaigns_for(user.id)
      ).not_to include(campaign_2)
      expect(
        described_class.all_campaigns_for(user.id)
      ).not_to include(campaign_3)
    end

    it 'will show no campaigns if there are no played or owned' do
      user = FactoryBot.create(:user)

      expect(
        described_class.all_campaigns_for(user.id)
      ).not_to include(campaign)
      expect(
        described_class.all_campaigns_for(user.id)
      ).not_to include(campaign_2)
      expect(
        described_class.all_campaigns_for(user.id)
      ).not_to include(campaign_3)
    end
  end

  describe 'destroy' do
    it 'will remove all players as well' do
      expect { campaign.destroy }.to change(CampaignsUser, :count).by(-1)
    end

    it 'will remove all hierarchy_elements as well' do
      expect { campaign.destroy }.to change(HierarchyElement, :count).by(-1)
    end
  end

  describe 'visible_to' do
    before do
      campaign.update(is_public: false)
    end

    describe 'nil user' do
      it 'is true to public campaigns' do
        campaign.update(is_public: true)

        expect(campaign.visible_to).to eq(true)
      end

      it 'is false to private campaigns' do
        expect(campaign.visible_to).to eq(false)
      end
    end

    describe 'player' do
      it 'is true for players of the campaign' do
        expect(campaign.visible_to(player)).to eq(true)
      end

      it 'is false for players of other campaigns' do
        user = FactoryBot.create(:user)

        expect(campaign.visible_to(user)).to eq(false)
      end
    end

    it 'is allways true to the owner of the campaign' do
      author = campaign.user

      expect(campaign.visible_to(author)).to eq(true)
    end
  end
end
