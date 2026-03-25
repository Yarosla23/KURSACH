class ExperimentRunner
  TIME_RANGE = 1..17

  def initialize(experiment)
    @experiment = experiment
    @attack = experiment.attack
  end

  def run
    Experiment.transaction do
      @experiment.experiment_results.delete_all
      @experiment.adjacency_matrix&.destroy!

      TIME_RANGE.each do |t|
        attack_prob = @attack.probability_at(t)
        detect_prob = @experiment.p_single.clamp(0.0, 1.0)
        p_single = ProbabilityService.single_test(detect_prob, @experiment.k)
        p_collab = ProbabilityService.collab_test(detect_prob, @experiment.k, @experiment.n)

        # Частный случай формулы (7) для одной выбранной атаки:
        # pA(отк) = p(ai) * p(отк|Ai)
        p_fail = @experiment.p_ai * attack_prob

        # Формулы (8) и (9)
        p_single_c = ProbabilityService.with_counteraction(p_single, p_fail)
        p_collab_c = ProbabilityService.with_counteraction(p_collab, p_fail)

        ExperimentResult.create!(
          experiment_id: @experiment.id,
          t: t,
          p_attack: attack_prob,
          p_single: p_single,
          p_collab: p_collab,
          p_single_counter: p_single_c,
          p_collab_counter: p_collab_c
        )
      end

      matrix = MatrixGenerator.generate
      cover = GreedyCover.cover(matrix)

      @experiment.create_adjacency_matrix!(
        data: {
          matrix: matrix,
          cover: cover
        }
      )
    end
  end
end
