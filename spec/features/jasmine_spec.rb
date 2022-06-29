RSpec.describe 'jasmine', type: :feature, js: true, logged: :admin do

  it 'run tests' do
    visit "/dummy_entities?jasmine=true"
    expect(page).to have_css('.jasmine-bar')
    expect(page.evaluate_script('window.jasmineHelper.parseResult();')).to eq('success')
  end

end
