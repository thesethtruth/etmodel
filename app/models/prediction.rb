# == Schema Information
#
# Table name: predictions
#
#  id               :integer(4)      not null, primary key
#  input_element_id :integer(4)
#  user_id          :integer(4)
#  expert           :boolean(1)
#  curve_type       :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  description      :text
#  title            :string(255)
#

class Prediction < ActiveRecord::Base
  belongs_to :user
  belongs_to :input_element
  has_many :values,   :class_name => "PredictionValue",   :dependent => :destroy, :order => 'year ASC'
  has_many :measures, :class_name => "PredictionMeasure", :dependent => :destroy
    
  has_paper_trail

  accepts_nested_attributes_for :values,   :allow_destroy => true, :reject_if => :all_blank
  accepts_nested_attributes_for :measures, :allow_destroy => true, :reject_if => :all_blank
  
  def last_value
    @last_value ||= values.future_first.first
  end
end
