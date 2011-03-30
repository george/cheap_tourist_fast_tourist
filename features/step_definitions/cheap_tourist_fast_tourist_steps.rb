Given /^a file named "([^"]*)"$/ do |file_name|
  Given %Q{an empty file named "#{file_name}"}
end

Then /^the output should contain usage information$/ do
  Then "the output should contain:", usage_information
end

Then /^the output should not contain usage information$/ do
  Then "the output should not contain:", usage_information
end

# debugging
Then /^show me the output$/ do
  puts <<-EOS

  ~~~~~~~~~~~~~~~~~~~~~~

  #{all_output}

  ~~~~~~~~~~~~~~~~~~~~~~

  EOS
end
