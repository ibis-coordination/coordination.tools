require "test_helper"

class AccountTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @user = User.create!(name: "Alex", email: "alex@example.com")
  end

  test "the header shows your name, not your email" do
    sign_in_as(@user)
    get root_path

    assert_select ".session-nav a", text: "Alex"
    assert_select ".session-nav", text: /alex@example\.com/, count: 0
  end

  test "requesting an email change emails the new address and changes nothing yet" do
    sign_in_as(@user)

    assert_enqueued_emails 1 do
      patch account_path, params: { user: { email: "new@example.com" } }
    end

    assert_equal "alex@example.com", @user.reload.email
    assert_equal "new@example.com", @user.pending_email

    perform_enqueued_jobs
    assert_equal ["new@example.com"], ActionMailer::Base.deliveries.last.to
  end

  test "confirming the emailed link applies the email change" do
    sign_in_as(@user)
    patch account_path, params: { user: { email: "new@example.com" } }

    token = @user.reload.generate_token_for(:email_change)
    get confirm_email_account_path(token: token)

    @user.reload
    assert_equal "new@example.com", @user.email
    assert_nil @user.pending_email
    assert @user.email_confirmed?
  end

  test "an email taken by another account is rejected" do
    User.create!(name: "Sam", email: "sam@example.com")
    sign_in_as(@user)

    assert_no_enqueued_emails do
      patch account_path, params: { user: { email: "sam@example.com" } }
    end
    assert_nil @user.reload.pending_email
  end

  test "a stale link no longer applies after a newer change request" do
    sign_in_as(@user)
    patch account_path, params: { user: { email: "first@example.com" } }
    stale_token = @user.reload.generate_token_for(:email_change)
    patch account_path, params: { user: { email: "second@example.com" } }

    get confirm_email_account_path(token: stale_token)

    assert_equal "alex@example.com", @user.reload.email
  end

  test "the name-editing gate explains itself" do
    sign_in_as_unconfirmed = post session_path, params: { user: { email: "fresh@example.com" } }
    post session_path, params: { user: { name: "Fresh", email: "fresh@example.com" } }
    get edit_account_path

    assert_match(/impersonat/i, response.body)
  end
end
