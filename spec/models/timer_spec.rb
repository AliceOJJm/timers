require 'rails_helper'

RSpec.describe Timer, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:execution_time) }
    it { is_expected.to validate_presence_of(:url) }
    it { should_not allow_value('Inv4lid').for(:url) }
    it { should_not allow_value('').for(:url) }
    it { should_not allow_value('http://g').for(:url) }
    it { should_not allow_value('whatever://g.com').for(:url) }
    it { should allow_value('https://g.com').for(:url) }
    it { should allow_value('https://g.com/path').for(:url) }
    it { should allow_value('https://g.com/path?queryparam=1').for(:url) }
  end
end
