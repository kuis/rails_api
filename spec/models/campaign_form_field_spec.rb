# == Schema Information
#
# Table name: campaign_form_fields
#
#  id                :integer          not null, primary key
#  campaign_id       :integer
#  kpi_id            :integer
#  ordering          :integer
#  name              :string(255)
#  field_type        :string(255)
#  options           :text
#  section_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  capture_mechanism :string(255)
#

require 'spec_helper'

describe CampaignFormField do
  pending "add some examples to (or delete) #{__FILE__}"
end
