module ApplicationHelper
  CHART_COLORS = [
    "#2563eb",
    "#dc2626",
    "#059669",
    "#d97706",
    "#7c3aed",
    "#0891b2",
    "#e11d48",
    "#65a30d"
  ].freeze

  def chart_canvas(series, **options)
    height = options[:height] || "420px"
    canvas_id = "chart-#{SecureRandom.hex(8)}"
    config = chart_js_config(series, **options)

    content_tag(:div, class: "relative w-full", style: "height: #{height};") do
      safe_join([
        content_tag(:canvas, "", id: canvas_id, class: "w-full h-full"),
        javascript_tag(<<~JS)
          (() => {
            const renderChart = () => {
              const canvas = document.getElementById("#{canvas_id}");
              if (!canvas || !window.Chart) return;

              if (canvas.dataset.chartInitialized === "true") return;
              canvas.dataset.chartInitialized = "true";

              const config = #{config.to_json};
              config.options ||= {};
              config.options.plugins ||= {};
              config.options.plugins.tooltip ||= {};
              config.options.plugins.tooltip.callbacks ||= {};
              config.options.plugins.tooltip.callbacks.label = (context) => {
                const label = context.dataset?.label || "Серия";
                const value = typeof context.parsed?.y === "number" ? context.parsed.y.toFixed(4) : context.parsed?.y;
                return `${label}: ${value}`;
              };

              new window.Chart(canvas, config);
            };

            if (document.readyState === "loading") {
              document.addEventListener("DOMContentLoaded", renderChart, { once: true });
            } else {
              renderChart();
            }

            document.addEventListener("turbo:load", renderChart, { once: true });
          })();
        JS
      ])
    end
  end

  private

  def chart_js_config(series, **options)
    normalized_series = normalize_chart_series(series)
    values = extract_chart_values(normalized_series)
    y_min, y_max = adaptive_chart_range(values)
    step_size = adaptive_step_size(y_min, y_max)
    numeric_x_axis = numeric_x_axis?(normalized_series)

    {
      type: "line",
      data: {
        datasets: build_chart_datasets(normalized_series, show_points: options.fetch(:points, false))
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        normalized: true,
        parsing: false,
        interaction: {
          mode: "nearest",
          intersect: false
        },
        plugins: {
          legend: {
            display: normalized_series.size > 1
          },
          tooltip: {}
        },
        scales: {
          x: chart_x_scale(options[:xtitle], numeric_x_axis),
          y: chart_y_scale(options[:ytitle], y_min, y_max, step_size)
        }
      }
    }
  end

  def chart_x_scale(title, numeric_x_axis)
    scale = {
      title: {
        display: title.present?,
        text: title
      },
      grid: {
        color: "rgba(148, 163, 184, 0.12)"
      },
      ticks: {
        color: "#475569"
      }
    }

    scale[:type] = "linear" if numeric_x_axis
    scale
  end

  def chart_y_scale(title, min_value, max_value, step_size)
    ticks = {
      color: "#475569",
      callback: nil
    }
    ticks[:stepSize] = step_size if step_size

    {
      min: min_value,
      max: max_value,
      title: {
        display: title.present?,
        text: title
      },
      grid: {
        color: "rgba(148, 163, 184, 0.12)"
      },
      ticks: ticks
    }
  end

  def build_chart_datasets(series, show_points:)
    series.each_with_index.map do |item, index|
      color = CHART_COLORS[index % CHART_COLORS.length]

      {
        label: item[:name],
        data: item[:data].map { |x, y| { x: normalize_chart_number(x), y: normalize_chart_number(y) } },
        borderColor: color,
        backgroundColor: "#{color}33",
        borderWidth: 2,
        tension: 0.28,
        pointRadius: show_points ? 2.5 : 0,
        pointHoverRadius: show_points ? 4 : 3,
        fill: false
      }
    end
  end

  def normalize_chart_series(series)
    case series
    when Array
      if series.all? { |item| chart_point?(item) }
        [{ name: "Серия 1", data: normalize_chart_points(series) }]
      elsif series.all? { |item| item.is_a?(Hash) && (item.key?(:data) || item.key?("data")) }
        series.map.with_index do |item, index|
          {
            name: item[:name] || item["name"] || "Серия #{index + 1}",
            data: normalize_chart_points(item[:data] || item["data"])
          }
        end
      else
        []
      end
    when Hash
      if series.key?(:data) || series.key?("data")
        [
          {
            name: series[:name] || series["name"] || "Серия 1",
            data: normalize_chart_points(series[:data] || series["data"])
          }
        ]
      else
        []
      end
    else
      []
    end
  end

  def normalize_chart_points(points)
    Array(points).filter_map do |point|
      next unless chart_point?(point)

      [point[0], point[1]]
    end
  end

  def chart_point?(item)
    item.respond_to?(:to_a) && item.to_a.length == 2 && numeric_like?(item.to_a.last)
  end

  def adaptive_chart_range(values)
    return [0.0, 1.0] if values.empty?

    raw_min = values.min
    raw_max = values.max
    spread = raw_max - raw_min

    min_value, max_value =
      if spread.abs < 1e-9
        padding = [raw_max.abs * 0.15, 0.001].max
        [raw_min - padding, raw_max + padding]
      else
        padding = [spread * 0.12, raw_max.abs * 0.03, 0.001].max
        [raw_min - padding, raw_max + padding]
      end

    [[min_value, 0.0].max, [max_value, 1.0].min]
  end

  def adaptive_step_size(min_value, max_value)
    span = max_value - min_value

    if span <= 0.02
      0.002
    elsif span <= 0.05
      0.005
    elsif span <= 0.1
      0.01
    elsif span <= 0.2
      0.02
    end
  end

  def extract_chart_values(series)
    series.flat_map do |item|
      item[:data].filter_map do |(_x, y)|
        numeric_like?(y) ? y.to_f : nil
      end
    end
  end

  def numeric_x_axis?(series)
    series.flat_map { |item| item[:data].map(&:first) }.all? { |value| numeric_like?(value) }
  end

  def normalize_chart_number(value)
    numeric_like?(value) ? value.to_f : value.to_s
  end

  def numeric_like?(value)
    Float(value)
    true
  rescue ArgumentError, TypeError
    false
  end
end
