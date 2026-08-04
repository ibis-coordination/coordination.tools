require "test_helper"

class SiteChromeTest < ActionDispatch::IntegrationTest
  test "the header shows the logo next to the wordmark" do
    get root_path

    # The SVG inverts with the OS color scheme, matching the site chrome.
    assert_select "header .brand img.brand-logo[src='/icon.svg']"
    assert_select "header .brand", text: /coordination\.tools/
  end

  test "the page declares support for light and dark color schemes" do
    get root_path

    assert_select "meta[name='color-scheme'][content='light dark']"
  end

  test "the footer credits Ibis Coordination with a link" do
    get root_path

    assert_select "footer", text: /Built by Ibis Coordination/
    assert_select "footer a[href='https://ibis-coordination.com']", text: "Ibis Coordination"
  end
end
