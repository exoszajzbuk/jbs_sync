require 'spec_helper'

describe Synchronization do

  def reset_synchronization(options = {})
    @valid_attributes = {
      :id => 1,
      :model_name => "RSpec is great for testing too"
    }

    @synchronization.destroy! if @synchronization
    @synchronization = Synchronization.create!(@valid_attributes.update(options))
  end

  before(:each) do
    reset_synchronization
  end

  context "validations" do
    
    it "rejects empty model_name" do
      Synchronization.new(@valid_attributes.merge(:model_name => "")).should_not be_valid
    end

    it "rejects non unique model_name" do
      # as one gets created before each spec by reset_synchronization
      Synchronization.new(@valid_attributes).should_not be_valid
    end
    
  end

end