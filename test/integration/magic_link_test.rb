require "test_helper"

class MagicLinkTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @user = User.create!(name: "Organizer", email: "organizer@example.com")
  end

  test "a new email signs up instantly without confirmation" do
    assert_emails 0 do
      post session_path, params: { user: { name: "Fresh", email: "fresh@example.com" } }
    end
    assert_redirected_to root_path
    user = User.find_by!(email: "fresh@example.com")
    assert_nil user.email_confirmed_at

    get new_carpool_path
    assert_response :success # signed in
  end

  test "an existing email gets a magic link instead of a session" do
    assert_emails 1 do
      post session_path, params: { user: { name: "Whoever", email: " ORGANIZER@example.com " } }
    end
    assert_redirected_to new_session_path

    email = ActionMailer::Base.deliveries.last
    assert_equal ["organizer@example.com"], email.to
    assert_match %r{/session/confirm\?token=}, email.text_part.body.to_s
    assert_match %r{/session/confirm\?token=}, email.html_part.body.to_s

    get new_carpool_path
    assert_redirected_to new_session_path # still signed out
  end

  test "the magic link signs in and confirms the email" do
    get confirm_session_path(token: @user.generate_token_for(:magic_link))

    assert_redirected_to root_path
    assert @user.reload.email_confirmed_at.present?
    get new_carpool_path
    assert_response :success # signed in
  end

  test "an invalid or expired link does not sign in" do
    get confirm_session_path(token: "garbage")
    assert_redirected_to new_session_path

    token = @user.generate_token_for(:magic_link)
    travel 31.minutes do
      get confirm_session_path(token: token)
      assert_redirected_to new_session_path
      get new_carpool_path
      assert_redirected_to new_session_path # still signed out
    end
    assert_nil @user.reload.email_confirmed_at
  end

  test "the magic link honors a stored return path" do
    carpool = @user.carpools.create!(name: "Beach day", destination: "Ocean Beach", starts_at: 2.days.from_now)
    get new_session_path(return_to: carpool_path(carpool))
    post session_path, params: { user: { email: "organizer@example.com" } }

    get confirm_session_path(token: @user.generate_token_for(:magic_link))

    assert_redirected_to carpool_path(carpool)
  end

  test "a confirmed user can edit their name" do
    sign_in_as(@user) # signs in via magic link, so the email is confirmed

    patch account_path, params: { user: { name: "Danielle" } }

    assert_redirected_to edit_account_path
    assert_equal "Danielle", @user.reload.name
  end

  test "an unconfirmed user cannot edit their name" do
    post session_path, params: { user: { name: "Fresh", email: "fresh@example.com" } }
    user = User.find_by!(email: "fresh@example.com")

    patch account_path, params: { user: { name: "Changed" } }

    assert_response :redirect
    assert_equal "Fresh", user.reload.name
  end
end
