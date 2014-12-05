require 'rails_helper'

describe TeamsController, type: :controller, search: true do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { user }

  describe "GET 'autocomplete'" do
    it 'should return the correct buckets in the right order' do
      Sunspot.commit
      get 'autocomplete'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map { |b| b['label'] }).to eq([
        'Teams', 'Users', 'Campaigns', 'Active State'])
    end

    it 'should return the teams in the Teams Bucket' do
      team = create(:team, name: 'Team 1', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', q: 'tea'
      expect(response).to be_success

      buckets = JSON.parse(response.body)

      teams_bucket = buckets.select { |b| b['label'] == 'Teams' }.first
      expect(teams_bucket['value']).to eq([{ 'label' => '<i>Tea</i>m 1', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'should return the users in the Users Bucket' do
      user = create(:user, first_name: 'Juanito', last_name: 'Bazooka', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'ju'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      users_bucket = buckets.select { |b| b['label'] == 'Users' }.first
      expect(users_bucket['value']).to eq([{ 'label' => '<i>Ju</i>anito Bazooka', 'value' => company_user.id.to_s, 'type' => 'user' }])
    end

    it 'should return the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Campaign 1', company_id: company.id)
      Sunspot.commit

      get 'autocomplete', q: 'cam'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([{ 'label' => '<i>Cam</i>paign 1', 'value' => campaign.id.to_s, 'type' => 'campaign' }])
    end
  end
end
