class OutputElementsController < ApplicationController
  layout false

  before_action :find_output_element, only: [:show, :zoom]

  # Returns all the data required to show a chart.
  # JSON only
  def show
    json = OutputElementPresenter.present(
      @chart, ->(*args) { render_to_string(*args) }
    )

    render(status: :ok, json: json)
  end

  # Returns all the data required to show multiple charts. Renders a JSON object
  # where each key matches that of the requested chart.
  def batch
    keys = params[:keys].to_s.split(',').reject(&:blank?).uniq

    json = OutputElementPresenter.collection(
      keys.map { |key| OutputElement.find(key) },
      ->(*args) { render_to_string(*args) }
    )

    render(status: :ok, json: json)
  end

  def index
    # id of the element the chart will be placed in
    @chart_holder = params[:holder]
    @groups = OutputElement.select_by_group

    respond_to do |wants|
      wants.html {}
      wants.json { render(json: GroupedOutputElementPresenter.new(@groups)) }
    end
  end

  def zoom
  end

  def collect_labels_and_gqueries
    output_element_keys = params[:keys].to_s.split(',').reject(&:blank?).uniq
    locale = params[:locale] || I18n.default_locale

    labels_and_gqueries = output_element_keys.each_with_object([]) do |key, collection|
      file_path = Rails.root.join('config', 'interface', 'output_element_series', "#{key}.yml")

      if File.exist?(file_path)
        data = YAML.load_file(file_path)
        data.each do |label, gquery|
          translated_label = I18n.t("output_element_series.labels.#{label}", locale: locale)
          collection << { translated_label => gquery }
        end
      end
    end

    formatted_data = format_to_yaml_structure(labels_and_gqueries)

    render(status: :ok, json: formatted_data.to_json)
  end

  private

  def find_output_element
    @as_table = params[:format] == 'table'

    @chart = OutputElement.find!(params[:key])
  end

  def format_to_yaml_structure(data)
    schema = data.map do |hash|
      { 'name' => hash.keys.first, 'type' => 'query' }
    end

    rows = data.map do |hash|
      { hash.keys.first => hash.values.first }
    end

    {
      'schema' => schema,
      'rows' => rows
    }
  end
end
