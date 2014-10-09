# == Schema Information
#
# Table name: activities
#
#  id               :integer          not null, primary key
#  activity_type_id :integer
#  activitable_id   :integer
#  activitable_type :string(255)
#  campaign_id      :integer
#  active           :boolean          default(TRUE)
#  company_user_id  :integer
#  activity_date    :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

describe Activity, type: :model do
  it { is_expected.to belong_to(:activity_type) }
  it { is_expected.to belong_to(:activitable) }
  it { is_expected.to belong_to(:company_user) }

  it { is_expected.to validate_presence_of(:activity_type_id) }
  it { is_expected.to validate_presence_of(:company_user_id) }
  it { is_expected.to validate_presence_of(:activity_date) }
  it { is_expected.to validate_numericality_of(:activity_type_id) }
  it { is_expected.to validate_numericality_of(:company_user_id) }

  describe 'inclusion of activity_type_id' do
    describe 'when assigned to a campaign' do
      before { subject.campaign = campaign }
      let(:company) { create(:company) }
      let(:campaign) { create(:campaign, company: company, activity_type_ids: activity_types.map(&:id)) }
      let(:activity_types) { create_list(:activity_type, 2, company: company) }
      let(:other_type) { create(:activity_type, company: company) }

      it { is_expected.to allow_value(activity_types.first.id).for(:activity_type_id) }
      it { is_expected.to allow_value(activity_types.second.id).for(:activity_type_id) }
      it { is_expected.not_to allow_value(other_type.id).for(:activity_type_id) }
    end

    describe 'when assigned to a venue' do
      before { subject.campaign = nil }
      before { subject.activitable = venue }
      let(:company) { create(:company) }
      let(:venue) { create(:venue, company: company) }
      let(:activity_types) { create_list(:activity_type, 2, company: company) }
      let(:other_type) { create(:activity_type, company: create(:company)) }

      it { is_expected.to allow_value(activity_types.first.id).for(:activity_type_id) }
      it { is_expected.to allow_value(activity_types.second.id).for(:activity_type_id) }
      it { is_expected.not_to allow_value(other_type.id).for(:activity_type_id) }
    end

    describe 'when assigned to a venue' do
      before { subject.campaign = nil }
      before { subject.activitable = event }
      let(:company) { create(:company) }
      let(:campaign) { create(:campaign, company: company, activity_type_ids: activity_types.map(&:id)) }
      let(:event) { create(:event, campaign: campaign) }
      let(:activity_types) { create_list(:activity_type, 2, company: company) }
      let(:other_type) { create(:activity_type, company: company) }

      it { is_expected.to allow_value(activity_types.first.id).for(:activity_type_id) }
      it { is_expected.to allow_value(activity_types.second.id).for(:activity_type_id) }
      it { is_expected.not_to allow_value(other_type.id).for(:activity_type_id) }
    end
  end

  describe '#activate' do
    let(:activity) { build(:activity, active: false) }

    it 'should return the active value as true' do
      activity.activate!
      activity.reload
      expect(activity.active).to be_truthy
    end
  end

  describe '#deactivate' do
    let(:activity) { build(:activity, active: false) }

    it 'should return the active value as false' do
      activity.deactivate!
      activity.reload
      expect(activity.active).to be_falsey
    end
  end

  describe "with_results_for" do
    let(:activity_type) { FactoryGirl.create(:activity_type, company: campaign.company) }
    let(:field) { FactoryGirl.create(:form_field, type: 'FormField::TextArea', fieldable: activity_type ) }
    let(:venue) { FactoryGirl.create(:venue, company: campaign.company) }
    let(:campaign) { FactoryGirl.create(:campaign) }

    before { campaign.activity_types << activity_type }

    it "results empty if no activities have the given fields" do
      FactoryGirl.create(:activity, activity_type: activity_type,
        activitable: venue, campaign: campaign, company_user_id: 1)
      expect(Activity.with_results_for(field)).to be_empty
    end

    it "results the activity if have result for the field" do
      activity = FactoryGirl.create(:activity, activity_type: activity_type,
        activitable: venue, campaign: campaign, company_user_id: 1)
      activity.results_for([field]).first.value = 'this have a value'
      activity.save

      expect(Activity.with_results_for(field)).to match_array [activity]
    end

    it "should return each activity only once" do
      activity = FactoryGirl.create(:activity, activity_type: activity_type,
        activitable: venue, campaign: campaign, company_user_id: 1)

      field2 = FactoryGirl.create(:form_field, type: 'FormField::TextArea', fieldable: activity_type )
      activity.results_for([field, field2]).each{|r| r.value = 'this have a value' }
      expect {
        activity.save
      }.to change(FormFieldResult, :count).by(2)

      expect(Activity.with_results_for([field, field2])).to match_array [activity]
    end
  end

  describe "all_values_for_trending" do
    let(:activity_type) { FactoryGirl.create(:activity_type, company: campaign.company) }
    let(:field) { FactoryGirl.create(:form_field, type: 'FormField::TextArea', fieldable: activity_type ) }
    let(:venue) { FactoryGirl.create(:venue, company: campaign.company) }
    let(:campaign) { FactoryGirl.create(:campaign) }
    let(:activity) { FactoryGirl.create(:activity, activity_type: activity_type,
            activitable: venue, campaign: campaign, company_user_id: 1) }

    before { campaign.activity_types << activity_type }

    it "results empty if no activities have the given fields" do
      expect(activity.all_values_for_trending).to be_empty
    end

    it "returns all the values for all trending fields" do
      field2 = FactoryGirl.create(:form_field, type: 'FormField::TextArea', fieldable: activity_type )

      activity.results_for([field]).first.value = 'this have a value'
      activity.results_for([field2]).first.value = 'another value'
      activity.save

      expect(activity.all_values_for_trending).to match_array ['this have a value', 'another value']
    end

    it "returns all the values for all trending fields that match the given term" do
      field2 = FactoryGirl.create(:form_field, type: 'FormField::TextArea', fieldable: activity_type )

      activity.results_for([field]).first.value = 'this have a value'
      activity.results_for([field2]).first.value = 'another value'
      activity.save

      expect(activity.all_values_for_trending('another')).to match_array ['another value']
      expect(activity.all_values_for_trending('value')).to match_array ['this have a value', 'another value']
    end
  end
end
