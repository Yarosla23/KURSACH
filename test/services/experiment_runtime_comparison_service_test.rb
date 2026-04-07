require "test_helper"

class ExperimentRuntimeComparisonServiceTest < ActiveSupport::TestCase
  test "builds runtime comparison rows for current experiment parameters" do
    experiment = experiments(:one)

    analysis = ExperimentRuntimeComparisonService.new(experiment).call

    assert_equal 17, analysis[:rows].size
    assert_equal 17, analysis[:series][:single].first[:data].size
    assert_equal 17, analysis[:series][:collab].first[:data].size
    assert_equal 17, analysis[:series][:counter_compare].first[:data].size
    assert_operator analysis[:insights].size, :>=, 4

    first_row = analysis[:rows].first
    expected_single = ProbabilityService.single_test(experiment.p_single, experiment.k)
    expected_collab = ProbabilityService.collab_test(experiment.p_single, experiment.k, experiment.n)
    expected_attack = experiment.attack.probability_at(1)
    expected_fail = experiment.p_ai * expected_attack

    assert_in_delta expected_single, first_row[:single_base], 1e-9
    assert_in_delta expected_collab, first_row[:collab_base], 1e-9
    assert_in_delta expected_attack, first_row[:p_attack], 1e-9
    assert_in_delta expected_fail, first_row[:p_fail], 1e-9
  end
end
