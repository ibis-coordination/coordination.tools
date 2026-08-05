require "test_helper"

class DecisionTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(name: "Owner", email: "owner@example.com")
    @voter = User.create!(name: "Voter", email: "voter@example.com")
    @decision = @owner.decisions.create!(question: "Where should we go?")
    @a = @decision.decision_options.create!(title: "Beach", user: @owner)
    @b = @decision.decision_options.create!(title: "Mountains", user: @owner)
  end

  test "results rank acceptance before preference" do
    DecisionVote.create!(decision: @decision, decision_option: @a, user: @owner, accepted: true, preferred: false)
    DecisionVote.create!(decision: @decision, decision_option: @a, user: @voter, accepted: true, preferred: false)
    DecisionVote.create!(decision: @decision, decision_option: @b, user: @owner, accepted: true, preferred: true)
    assert_equal [@a, @b], @decision.results.to_a
  end

  test "results break equal vote totals randomly" do
    sql = @decision.results.to_sql

    assert_includes sql, "RANDOM()"
    assert_not_includes sql, "decision_options.created_at ASC"
  end

  test "a preferred option must be accepted" do
    vote = DecisionVote.new(decision: @decision, decision_option: @a, user: @voter, preferred: true)
    assert_not vote.valid?
  end

  test "closed decisions reject options and votes" do
    @decision.update!(closed_at: Time.current)
    assert_not @decision.decision_options.new(title: "City", user: @voter).valid?
    assert_not DecisionVote.new(decision: @decision, decision_option: @a, user: @voter, accepted: true).valid?
  end
end
