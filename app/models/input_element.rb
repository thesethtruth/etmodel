# == Schema Information
#
# Table name: input_elements
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  key                :string(255)
#  share_group        :string(255)
#  step_value         :float
#  created_at         :datetime
#  updated_at         :datetime
#  unit               :string(255)
#  input_element_type :string(255)
#  label              :string(255)
#  comments           :text
#  interface_group    :string(255)
#  input_id           :integer(4)
#  command_type       :string(255)
#

class InputElement < ActiveRecord::Base
  CONVERSIONS = YAML.load(Rails.root.join('db', 'unit_conversions.yml'))

  include AreaDependent
  has_paper_trail

  has_one :description, :as => :describable
  has_one :area_dependency, :as => :dependable
  has_many :predictions

  validates :key, :presence => true, :uniqueness => true
  validates :input_id, :presence => true

  scope :households_heating_sliders, where(:share_group => 'heating_households')

  accepts_nested_attributes_for :description


  def title_for_description
    "slider.#{name}"
  end

  def translated_name
    I18n.t(title_for_description)
  end

  def search_result
    SearchResult.new(name, description)
  end

  define_index do
    indexes name
    indexes description(:content_en), :as => :description_content_en
    indexes description(:content_nl), :as => :description_content_nl
    indexes description(:short_content_en), :as => :description_short_content_en
    indexes description(:short_content_nl), :as => :description_short_content_nl
  end


  def cache_conditions_key
    [self.class.name, self.id, Current.setting.area.id].join('_')
  end

  # Cache
  def cache(method, options = {}, &block)
    if options[:cache] == false
      yield
    else
      Rails.cache.fetch("%s-%s" % [cache_conditions_key, method.to_s]) do
        yield
      end
    end
  end

  def disabled
    input_element_type == 'fixed'
  end

  # Retrieves an array of suitable unit conversions for the element. Allows
  # the user to swap between different unit types in the UI.
  #
  # @return [Array(Hash)]
  #
  def conversions
    CONVERSIONS[key] || Array.new
  end

  def available_predictions(area = nil)
    predictions.for_area(area || Current.setting.region)
  end

  def has_predictions?
    return false unless Current.backcasting_enabled
    available_predictions(Current.setting.region).any?
  end
  alias_method :has_predictions, :has_predictions?

  #############################################
  # Methods that interact with a users values
  #############################################

  def as_json(options = {})
    super(:only => [:id, :input_id, :name, :unit, :share_group, :factor],
          :methods => [
            :step_value,
            :output, :user_value, :disabled, :translated_name, 
            :parsed_description,:has_predictions,
    :input_element_type, :has_flash_movie])
  end

  ##
  # For showing the name and the action of the inputelement in the admin
  #

  def parsed_name_for_admin
    "#{key} | #{name} | #{unit} | #{input_element_type}"
  end

  def has_flash_movie
    description.andand.content.andand.include?("player")  || description.andand.content.andand.include?("object")
  end

  ##
  # For loading multiple flowplayers classname is needed instead of id
  # added the andand check and html_safe to clean up the helper
  #
  def parsed_description
    (description.andand.content.andand.gsub('id="player"','class="player"') || "").html_safe
  end
end
