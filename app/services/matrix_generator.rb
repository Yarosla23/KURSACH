class MatrixGenerator
  SIZE = 15
  MIN_EDGES = 1
  MAX_EDGES = 6
  MAX_ATTEMPTS = 30

  def self.generate
    MAX_ATTEMPTS.times do
      matrix = build_matrix
      return matrix if all_columns_covered?(matrix)
    end

    ensure_all_columns_covered(build_matrix)
  end

  def self.build_matrix
    Array.new(SIZE) do |i|
      row = Array.new(SIZE, 0)
      degree = rand(MIN_EDGES..MAX_EDGES)
      ((0...SIZE).to_a - [i]).sample(degree).each { |j| row[j] = 1 }
      row
    end
  end

  def self.all_columns_covered?(matrix)
    SIZE.times.all? { |j| matrix.any? { |row| row[j] == 1 } }
  end

  def self.ensure_all_columns_covered(matrix)
    uncovered_columns = (0...SIZE).reject { |j| matrix.any? { |row| row[j] == 1 } }

    uncovered_columns.each do |column|
      candidate_rows = (0...SIZE).to_a - [column]
      row_index = candidate_rows.sample

      if matrix[row_index].count(1) < MAX_EDGES
        matrix[row_index][column] = 1
      else
        removable = matrix[row_index].each_index.select { |index| matrix[row_index][index] == 1 && index != column }
        matrix[row_index][removable.sample] = 0 if removable.any?
        matrix[row_index][column] = 1
      end
    end

    matrix
  end

  private_class_method :build_matrix, :all_columns_covered?, :ensure_all_columns_covered
end
