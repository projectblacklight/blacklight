# frozen_string_literal: true

RSpec.describe 'Generated test application template at default path' do
  let(:target_template) { File.join('.internal_test_app', 'app', 'components', 'blacklight', 'top_navbar_component.html.erb') }

  before do
    FileUtils.mkdir_p('.internal_test_app/app/components/blacklight')
    src_template = File.join(Blacklight::Engine.root, 'app', 'components', 'blacklight', 'top_navbar_component.html.erb')
    contents = File.read(src_template).gsub('role="navigation"', 'role="navigation" data-template-override="top_navbar_component"')
    File.write(target_template, contents)
  end

  after do
    FileUtils.rm(target_template)
  end

  it 'unobtrusively overrides default top navbar component template' do
    visit root_path
    expect(page).to have_css 'nav[data-template-override="top_navbar_component"]'
  end
end
