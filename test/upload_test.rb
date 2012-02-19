require File.expand_path(File.dirname(__FILE__)) + "/../lib/upload.rb"
require "test/unit"

class UploadTest < Test::Unit::TestCase
  def test_url
    assert_equal "/upload/abc.mp4", Upload.new("abc",    :filename => "foo.mp4").url
    assert_equal "/upload/abc.mp4", Upload.new("../abc", :filename => "foo.mp4").url
  end

  def test_generate_id
    assert_match /^[0-9a-f]{32}$/, Upload.generate_id
  end
end
