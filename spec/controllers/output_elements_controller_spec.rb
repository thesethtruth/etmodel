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
      file_path = Rails.root.join('config', 'interface', 'output_element_series', 'example_key.yml')
      yaml_content = {
        'label1' => 'gquery1',
        'label2' => 'gquery2'
      }.to_yaml

      # Mock the file system to avoid dependency on real files
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(YAML).to receive(:load_file).with(file_path).and_return(YAML.load(yaml_content))
    end

    it 'collects labels and gqueries from the YAML files' do
      get :collect_labels_and_gqueries, params: { keys: 'example_key' }
      result = assigns(:labels_and_gqueries)
      expect(result).to eq([['label1', 'gquery1'], ['label2', 'gquery2']])
    end

    it 'handles missing YAML files gracefully' do
      allow(File).to receive(:exist?).with(anything).and_return(false)
      get :collect_labels_and_gqueries, params: { keys: 'example_key' }
      result = assigns(:labels_and_gqueries)
      expect(result).to eq([])
    end
  end
end
