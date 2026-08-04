require "test_helper"

class SiteChromeTest < ActionDispatch::IntegrationTest
  test "the header shows the logo next to the wordmark" do
    get root_path

    assert_select "header .brand img.brand-logo[src='/icon.svg']"
    assert_select "header .brand", text: /coordination\.tools/
  end

  test "the footer credits Ibis Coordination with a link" do
    get root_path

    assert_select "footer", text: /Built by Ibis Coordination/
    assert_select "footer a[href='https://ibis-coordination.com']", text: "Ibis Coordination"
  end
end
