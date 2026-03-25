require "test_helper"

class AttackTest < ActiveSupport::TestCase
  test "calculates linear probability" do
    attack = attacks(:one)

    assert_in_delta 0.04, attack.probability_at(1), 1e-6
    assert_in_delta 0.52, attack.probability_at(17), 1e-6
  end

  test "calculates exponential probability" do
    attack = attacks(:two)

    assert_in_delta 0.135286, attack.probability_at(1), 1e-6
    assert_in_delta 0.544719, attack.probability_at(17), 1e-6
  end
end
