require "test_helper"

class ExperimentComparisonServiceTest < ActiveSupport::TestCase
  test "builds comparative rows and insights for the current experiment" do
    experiment = experiments(:one)

    analysis = ExperimentComparisonService.new(experiment).call

    assert_equal 0.75, analysis[:detection_probabilities][:high]
    assert_equal 0.47, analysis[:detection_probabilities][:low]
    assert_equal 17, analysis[:rows].size
    assert_equal 17, analysis[:series][:high].first[:data].size
    assert_equal 17, analysis[:series][:low].first[:data].size
    assert_operator analysis[:insights].size, :>=, 4

    first_row = analysis[:rows].first
    expected_attack = experiment.attack.probability_at(1)
    expected_fail = experiment.p_ai * expected_attack
    expected_high_single = ProbabilityService.with_counteraction(
      ProbabilityService.single_test(0.75, experiment.k),
      expected_fail
    )
    expected_high_collab = ProbabilityService.with_counteraction(
      ProbabilityService.collab_test(0.75, experiment.k, experiment.n),
      expected_fail
    )

    assert_in_delta expected_attack, first_row[:p_attack], 1e-9
    assert_in_delta expected_fail, first_row[:p_fail], 1e-9
    assert_in_delta expected_high_single, first_row[:high_single], 1e-9
    assert_in_delta expected_high_collab, first_row[:high_collab], 1e-9
  end
end
