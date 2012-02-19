require "test/unit"
require "capybara"
require "capybara/dsl"
require "rack"

Capybara.app = Rack::Builder.app do
  require File.expand_path(File.dirname(__FILE__)) + "/../app.rb"
  use UploadMiddleware
  run Sinatra::Application
end

require "capybara-webkit"
Capybara.default_driver = :webkit

class AcceptanceTest < Test::Unit::TestCase
  include Capybara::DSL
  def test_upload
    visit "/"
    assert_equal "width: 0;", find(".progress-bar span")["style"].strip,
      "The progress bar should be at 0% initially"

    attach_file "file", "test/fixtures/bass.jpg"
    assert find("#success").has_content?("Here's your file bass.jpg"),
      "A success message should appear"
    assert page.has_css?("#success a[href]"),
      "The success message should include a link"
    assert_equal "width: 100%;", find(".progress-bar span")["style"].strip,
      "The progress bar should now be at 100%"

    description_text = "Some description text"
    fill_in("description", :with => description_text)
    click_on("Save")

    assert page.has_content?(description_text),
      "After submission, the description text should be shown"
    assert page.has_content?("Your file bass.jpg is available"),
      "The name of the file should be mentioned"

    click_on("here")
    assert_equal "image/jpeg", page.response_headers["Content-Type"],
      "We should now be looking at the picture we just uploaded"
  end
end
