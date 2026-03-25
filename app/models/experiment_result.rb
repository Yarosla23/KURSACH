class ExperimentResult < ApplicationRecord
  belongs_to :experiment, inverse_of: :experiment_results
end
