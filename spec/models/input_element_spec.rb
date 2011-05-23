require 'spec_helper'

describe InputElement do

  describe "#step_value" do

    
    let(:original_step_value) { 0.07 } 

    it "should be 1/100th of value in database when controller name is supply and is locked for municipality" do
      Current.stub_chain(:setting, :area, :is_municipality?).and_return(true)
      Current.stub_chain(:setting, :municipality?).and_return(true)
      input_element = InputElement.new(:locked_for_municipalities => true, :step_value => original_step_value)
      input_element.stub_chain(:slide, :controller_name).and_return("supply")
      input_element.step_value.to_f.should be_within( 0.01).of(original_step_value/100)
    end
    
    it "should be equal to value in database when controller name is not supply and is locked for municipality" do
      Current.stub_chain(:scenario, :area, :is_municipality?).and_return(true)
      Current.stub_chain(:scenario, :municipality?).and_return(true)
      input_element = InputElement.new(:locked_for_municipalities => true, :step_value => original_step_value)
      input_element.stub_chain(:slide, :controller_name).and_return("demand")
      input_element.step_value.to_f.should be_within( 0.01).of(original_step_value)
    end

    it "should be equal to value in database when controller name is supply and is not locked for municipality" do
      Current.stub_chain(:scenario, :area, :is_municipality?).and_return(true)
      Current.stub_chain(:scenario, :municipality?).and_return(true)
      input_element = InputElement.new(:locked_for_municipalities => false, :step_value => original_step_value)
      input_element.stub_chain(:slide, :controller_name).and_return("demand")
      input_element.step_value.to_f.should be_within( 0.01).of(original_step_value)
    end

    it "should be equal to value in database when controller name is supply and is locked for municipality" do
      Current.stub_chain(:scenario, :area, :is_municipality?).and_return(false)
      Current.stub_chain(:scenario, :municipality?).and_return(false)
      input_element = InputElement.new(:locked_for_municipalities => true, :step_value => original_step_value)
      input_element.stub_chain(:slide, :controller_name).and_return("supply")
      input_element.step_value.to_f.should be_within( 0.01).of(original_step_value)
    end
        
  end
  
  
  describe "set correct input_elements as disabled" do
    it "should be true when input_element is has_locked_input_element_type?" do
      InputElement.stub!(:find).and_return([])
      input_element = InputElement.new
      input_element.has_locked_input_element_type?("fixed").should be_true
      input_element.has_locked_input_element_type?("share").should be_false
    end
  end

  describe "#caching of values" do
    pending
  end
end



