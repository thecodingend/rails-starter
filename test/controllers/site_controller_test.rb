require "test_helper"

class SiteControllerTest < ActionDispatch::IntegrationTest
  test "landing page renders" do
    get root_path
    assert_response :success
    assert_select "h1", text: /Agent-written code you'd actually merge/
  end

  test "blog index links to posts" do
    get "/blog"
    assert_response :success
    assert_select "a[href=?]", "/blog/the-briefing-is-part-of-the-codebase"
  end

  test "blog posts render markdown through the article layout" do
    get "/blog/the-briefing-is-part-of-the-codebase"
    assert_response :success
    assert_select "h1", text: "The briefing is part of the codebase"
    assert_select "article h2", minimum: 1
    assert_select "article pre code"
  end

  test "unknown paths are not served by the content glob route" do
    get "/definitely-not-a-page"
    assert_response :not_found
  end
end
