class GreedyCover
  def self.cover(matrix)
    size = matrix.size
    uncovered = (0...size).to_a
    selected_rows = []

    while uncovered.any?
      best_row = nil
      best_cover = []

      matrix.each_with_index do |row, i|
        next if selected_rows.include?(i)

        covers = uncovered.select { |col| row[col] == 1 }
        if covers.size > best_cover.size
          best_cover = covers
          best_row = i
        end
      end

      break if best_row.nil? || best_cover.empty?

      selected_rows << best_row
      uncovered -= best_cover
    end

    selected_rows
  end
end
