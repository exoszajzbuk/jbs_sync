Given /^I have no synchronizations$/ do
  Synchronization.delete_all
end

Given /^I (only )?have synchronizations titled "?([^\"]*)"?$/ do |only, titles|
  Synchronization.delete_all if only
  titles.split(', ').each do |title|
    Synchronization.create(:model_name => title)
  end
end

Then /^I should have ([0-9]+) synchronizations?$/ do |count|
  Synchronization.count.should == count.to_i
end
