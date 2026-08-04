require "test_helper"

class SignInFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "the sign-in form asks for email first, with no name field" do
    get new_session_path

    assert_select "input[name='user[email]']"
    assert_select "input[name='user[name]']", count: 0
  end

  test "an existing user signs in with only their email" do
    User.create!(name: "Organizer", email: "organizer@example.com")

    assert_enqueued_emails 1 do
      post session_path, params: { user: { email: "organizer@example.com" } }
    end
    assert_redirected_to new_session_path
  end

  test "a new email is asked for a name before an account is created" do
    assert_no_difference("User.count") do
      post session_path, params: { user: { email: "fresh@example.com" } }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='user[name]']"
    assert_select "input[type=hidden][name='user[email]'][value=?]", "fresh@example.com"
  end

  test "the name step discloses that name and email are visible to participants" do
    post session_path, params: { user: { email: "fresh@example.com" } }

    assert_match(/visible to/, response.body)
  end

  test "completing the name step creates the account and signs in" do
    post session_path, params: { user: { email: "fresh@example.com" } }
    post session_path, params: { user: { name: "Fresh", email: "fresh@example.com" } }

    assert_redirected_to root_path
    get new_carpool_path
    assert_response :success # signed in
  end

  test "an invalid email shows an error instead of the name step" do
    post session_path, params: { user: { email: "not-an-email" } }

    assert_response :unprocessable_entity
    assert_select "input[name='user[name]']", count: 0
    assert_match(/Email/, response.body)
  end
end
