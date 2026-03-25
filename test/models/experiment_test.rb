require "test_helper"

class ExperimentTest < ActiveSupport::TestCase
  test "is invalid when k is greater than n" do
    experiment = experiments(:one).dup
    experiment.n = 3
    experiment.k = 4

    assert_not experiment.valid?
    assert_includes experiment.errors[:k], "не может быть больше количества устройств n"
  end
end
