require 'rails_helper'

RSpec.describe 'autocomplete', type: :feature, js: true do

  describe 'render' do
    it 'generate default autocomplete' do
      visit '/dummy_autocompletes'
      expect(page).to have_css('input#default[type="text"]')
      expect(page).to have_css('input[type="hidden"][name="default"][value="value1"]', visible: false)
    end

    it 'generate autocomplete_field in form_for' do
      visit '/dummy_autocompletes'
      expect(page).to have_css('input#dummy_entities_autocomplete[type="text"]')
      expect(page).to have_css('input[type="hidden"][name="dummy_entity[array_of_dummies][]"][value="value1"]', visible: false)
    end
  end

end
