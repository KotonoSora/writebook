require "test_helper"

class PageTest < ActiveSupport::TestCase
  test "html preview" do
    page = Page.new(body: "# Hello\n\nWorld!")

    assert_match /<h1>Hello<\/h1>/, page.html_preview
    assert_match /<p>World!<\/p>/, page.html_preview
  end

  test "markable returns raw markdown content" do
    page = Page.new(body: "## Markdown Content\n\nWith **bold** text.")

    assert_equal "## Markdown Content\n\nWith **bold** text.", page.markable
  end

  test "markable returns empty string when body is empty" do
    page = Page.new(body: "")

    assert_equal "", page.markable
  end
end
