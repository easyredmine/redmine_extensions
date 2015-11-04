require 'rails_helper'

module RedmineExtensions
  RSpec.describe EasySettingPresenter, clear_cache: true do

    let(:project) { FactoryGirl.create(:project) }

    describe 'saving values' do
      it 'create easy_setting' do
        presenter = EasySettingPresenter.new({'key' => 'value', 'key2' => 'value2'})
        expect{ presenter.save }.to change(EasySetting, :count).by(2)
        expect( EasySetting.find_by(name: 'key').value ).to eq('value')
        expect( EasySetting.value('key') ).to eq('value')
      end

      it 'create project setting' do
        presenter = EasySettingPresenter.new({'key' => 'value', 'key2' => 'value2'}, project)
        expect{ presenter.save }.to change(EasySetting, :count).by(2)
        expect( EasySetting.where(project_id: project.id).count ).to eq(2)
        expect( EasySetting.value('key') ).to eq(nil)
        expect( EasySetting.value('key', project) ).to eq('value')
      end

      it 'format value' do
        presenter = EasySettingPresenter.new({'key' => '1', 'key2' => '0'})
        expect(presenter).to receive(:boolean_keys).at_least(:once).and_return([:key, :key2])
        presenter.save
        expect(EasySetting.value('key')).to be true
        expect(EasySetting.value('key2')).to be false
      end
    end

  end
end
