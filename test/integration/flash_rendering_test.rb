require "test_helper"

class FlashRenderingTest < ActionDispatch::IntegrationTest
  test "signing out shows a confirmation on the homepage" do
    user = User.create!(name: "Alex", email: "alex@example.com")
    sign_in_as(user)

    delete session_path
    follow_redirect!

    assert_match "Signed out.", response.body
  end

  test "signing up with no return path shows the signed-in notice on the homepage" do
    post session_path, params: { user: { name: "Alex", email: "alex@example.com" } }
    follow_redirect!

    assert_match "Signed in as alex@example.com.", response.body
  end

  test "flash messages are rendered once, not duplicated by per-view copies" do
    user = User.create!(name: "Alex", email: "alex@example.com")
    sign_in_as(user)
    follow_redirect!

    assert_select ".notice", count: 1
  end
end
