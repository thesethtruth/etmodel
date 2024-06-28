require 'rails_helper'

describe OutputElementsController, vcr: true do
  describe "#index" do
    it "should render the page correctly" do
      get :index
      expect(response).to be_successful
      expect(response).to render_template(:index)
    end
  end

  describe '#show' do
    let!(:output_element) { OutputElement.all.first }

    context 'with a key' do
      before { get(:show, params: { key: output_element.key }) }

      it 'responds successfully' do
        expect(response.status).to eq(200)
      end

      it 'assigns the output element' do
        expect(assigns(:chart)).to eq(output_element)
      end

      it 'responds with the chart attributes' do
        expect(JSON.parse(response.body)['attributes']).to include(
          'key' => output_element.key
        )
      end
    end

    context 'with an invalid key' do
      it 'responds 404 Not Found' do
        expect(get(:show, params: { key: 'nope' }).status).to eq(404)
      end
    end
  end # #show

  describe '#collect_labels_and_gqueries' do
    before do
      # Bypass authentication
      allow(controller).to receive(:authenticate_user!).and_return(true)

      file_path = Rails.root.join('config', 'interface', 'output_element_series', 'example_key.yml')
      yaml_content = {
        'label1' => 'gquery1',
        'label2' => 'gquery2'
      }.to_yaml

      # Mock the file system to avoid dependency on real files
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(YAML).to receive(:load_file).with(file_path).and_return(YAML.load(yaml_content))

      I18n.backend.store_translations(:en, { output_element_series: { labels: { label1: 'Label One', label2: 'Label Two' } } })
      I18n.backend.store_translations(:nl, { output_element_series: { labels: { label1: 'Label Een', label2: 'Label Twee' } } })
    end

    it 'collects labels and gqueries from the YAML files and translates labels to English' do
      get :collect_labels_and_gqueries, params: { keys: 'example_key', locale: 'en' }

      expected_response = {
        'schema' => [
          { 'name' => 'Label One', 'type' => 'query' },
          { 'name' => 'Label Two', 'type' => 'query' }
        ],
        'rows' => [
          { 'Label One' => 'gquery1' },
          { 'Label Two' => 'gquery2' }
        ]
      }

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq(expected_response.as_json)
    end

    it 'collects labels and gqueries from the YAML files and translates labels to Dutch' do
      get :collect_labels_and_gqueries, params: { keys: 'example_key', locale: 'nl' }

      expected_response = {
        'schema' => [
          { 'name' => 'Label Een', 'type' => 'query' },
          { 'name' => 'Label Twee', 'type' => 'query' }
        ],
        'rows' => [
          { 'Label Een' => 'gquery1' },
          { 'Label Twee' => 'gquery2' }
        ]
      }

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq(expected_response.as_json)
    end

    it 'handles missing YAML files gracefully' do
      allow(File).to receive(:exist?).with(anything).and_return(false)
      get :collect_labels_and_gqueries, params: { keys: 'example_key' }
      expected_response = { 'schema' => [], 'rows' => [] }

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq(expected_response.as_json)
    end
  end
end
