require 'rails_helper'

module EasySettings
  RSpec.describe ParamsWrapper, clear_cache: true do

    let(:project) { FactoryBot.create(:project) }

    describe 'saving values' do
      it 'create easy_setting' do
        presenter = EasySettings::ParamsWrapper.from_params({'key' => 'value', 'key2' => 'value2'})
        expect{ presenter.save }.to change(EasySetting, :count).by(2)
        expect( EasySetting.find_by(name: 'key').value ).to eq('value')
        expect( EasySetting.value('key') ).to eq('value')
      end

      it 'create project setting' do
        presenter = EasySettings::ParamsWrapper.from_params({'key' => 'value', 'key2' => 'value2'}, project: project)
        expect{ presenter.save }.to change(EasySetting, :count).by(2)
        expect( EasySetting.where(project_id: project.id).count ).to eq(2)
        expect( EasySetting.value('key') ).to eq(nil)
        expect( EasySetting.value('key', project) ).to eq('value')
      end

      it 'format value' do
        EasySetting.map.boolean_keys(:key, :key2)
        presenter = EasySettings::ParamsWrapper.from_params({'key' => '1', 'key2' => '0'})
        presenter.save
        expect(EasySetting.value('key')).to be true
        expect(EasySetting.value('key2')).to be false
      end
    end

  end
end
