require "test_helper"

class PictureTest < ActiveSupport::TestCase
  test "markable returns caption" do
    picture = Picture.new(caption: "A great picture")

    assert_equal "A great picture", picture.markable
  end

  test "markable returns nil when caption is nil" do
    picture = Picture.new(caption: nil)

    assert_nil picture.markable
  end
end
