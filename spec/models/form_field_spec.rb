# == Schema Information
#
# Table name: form_fields
#
#  id             :integer          not null, primary key
#  fieldable_id   :integer
#  fieldable_type :string(255)
#  name           :string(255)
#  type           :string(255)
#  settings       :text
#  ordering       :integer
#  required       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  kpi_id         :integer
#

require 'spec_helper'

describe FormField, :type => :model do
  it { is_expected.to belong_to(:fieldable) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:type) }
  it { is_expected.to validate_presence_of(:ordering) }
  it { is_expected.to validate_numericality_of(:ordering) }

  let(:field) { FormField.new }
  describe "#field_options" do
    it "should return basic options" do
      expect(field.field_options(FormFieldResult.new)).to eql(as: :string)
    end
  end

  describe "#field_classes" do
    it "should return generic class" do
      expect(field.field_classes).to eql(['input-xlarge'])
    end
  end

  describe "#store_value" do
    it "should return the values as is" do
      expect(field.store_value(1)).to eql 1
      expect(field.store_value("two")).to eql "two"
      expect(field.store_value(1.2)).to eql 1.2
    end
  end

  describe "#format_html" do
    it "should return the values as is" do
      expect(field.format_html(FactoryGirl.build(:form_field_result, value: nil, form_field: field))).to eql nil
      expect(field.format_html(FactoryGirl.build(:form_field_result, value: 1, form_field: field))).to eql 1
      expect(field.format_html(FactoryGirl.build(:form_field_result, value: "two", form_field: field))).to eql "two"
      expect(field.format_html(FactoryGirl.build(:form_field_result, value: 1.2, form_field: field))).to eql 1.2
    end
  end
end
