require 'rails_helper'

RSpec.describe EasySetting, type: :model do

  let(:project) { FactoryBot.create(:project, name: 'My project') }
  let!(:easy_setting) { EasySetting.create(name: 'my_setting', value: 'my_value', project_id: project.id) }
  let!(:easy_setting_global) { EasySetting.create(name: 'my_setting', value: 'my_value_global') }

  # cleanup since easy_seting is persistent and
  # is not deleted from db after tests are run
  after :each do
    [easy_setting, easy_setting_global].each &:destroy
  end

  it 'creates a setting for a project' do
    expect( easy_setting ).to be_persisted
  end

  it 'destroys settings when the project is destroyed' do
    easy_setting
    expect{ easy_setting.project.destroy }.to change(EasySetting, :count).by(-1)
  end

  it 'updates cache when changed' do
    new_value = 'my_new_value'
    easy_setting_global.value = new_value
    easy_setting_global.save

    assert_equal new_value, EasySetting.value('my_setting')
  end

  it 'invalidates the cache when deleted' do
    easy_setting.destroy
    easy_setting_global.destroy

    assert_nil EasySetting.value('my_setting')
  end

  it 'fallbacks to global setting when project specific not present' do
    easy_setting.destroy

    assert_equal easy_setting_global.value, EasySetting.value('my_setting')
  end

end
