(() => {
  const state = new WeakMap();
  const DEFAULT_VIEW = {
    azimuth: -0.72,
    elevation: -0.82,
    zoom: 0.32
  };

  function getConfig(canvas) {
    try {
      return JSON.parse(canvas.dataset.config || "{}");
    } catch (_error) {
      return {};
    }
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  function mixColor(a, b, t) {
    return [
      Math.round(lerp(a[0], b[0], t)),
      Math.round(lerp(a[1], b[1], t)),
      Math.round(lerp(a[2], b[2], t))
    ];
  }

  function valueColor(value, min, max) {
    const t = clamp((value - min) / (max - min || 1), 0, 1);
    const stops = [
      [37, 52, 148],
      [0, 114, 189],
      [50, 200, 210],
      [90, 210, 110],
      [255, 230, 80],
      [220, 38, 38]
    ];
    const scaled = t * (stops.length - 1);
    const index = Math.min(stops.length - 2, Math.floor(scaled));
    const local = scaled - index;
    const color = mixColor(stops[index], stops[index + 1], local);
    return `rgb(${color[0]}, ${color[1]}, ${color[2]})`;
  }

  function bilinear(values, x, z) {
    const rows = values.length;
    const cols = values[0] ? values[0].length : 0;
    if (!rows || !cols) return 0;

    const x0 = Math.floor(clamp(x, 0, cols - 1));
    const z0 = Math.floor(clamp(z, 0, rows - 1));
    const x1 = Math.min(cols - 1, x0 + 1);
    const z1 = Math.min(rows - 1, z0 + 1);
    const tx = x - x0;
    const tz = z - z0;

    const v00 = Number(values[z0][x0]) || 0;
    const v10 = Number(values[z0][x1]) || 0;
    const v01 = Number(values[z1][x0]) || 0;
    const v11 = Number(values[z1][x1]) || 0;

    return lerp(lerp(v00, v10, tx), lerp(v01, v11, tx), tz);
  }

  function buildSurface(config) {
    const values = Array.isArray(config.values) ? config.values : [];
    const rows = values.length;
    const cols = values[0] ? values[0].length : 0;
    if (!rows || !cols) return { points: [], xSteps: 0, zSteps: 0 };

    const xSteps = Math.max(24, Math.min(72, cols * 4));
    const zSteps = Math.max(24, Math.min(72, rows * 7));
    const points = [];

    for (let z = 0; z < zSteps; z += 1) {
      const row = [];
      const sourceZ = rows === 1 ? 0 : (z / (zSteps - 1)) * (rows - 1);

      for (let x = 0; x < xSteps; x += 1) {
        const sourceX = cols === 1 ? 0 : (x / (xSteps - 1)) * (cols - 1);
        row.push({
          x: (sourceX / Math.max(1, cols - 1) - 0.5) * 2,
          z: (sourceZ / Math.max(1, rows - 1) - 0.5) * 2,
          y: bilinear(values, sourceX, sourceZ)
        });
      }

      points.push(row);
    }

    return { points, xSteps, zSteps };
  }

  function project(point, view, width, height, yMin, yMax) {
    const az = view.azimuth;
    const el = view.elevation;
    const yNorm = ((point.y - yMin) / (yMax - yMin || 1)) * 1.45;

    const x1 = point.x * Math.cos(az) - point.z * Math.sin(az);
    const z1 = point.x * Math.sin(az) + point.z * Math.cos(az);
    const y1 = yNorm;
    const y2 = y1 * Math.cos(el) - z1 * Math.sin(el);
    const z2 = y1 * Math.sin(el) + z1 * Math.cos(el);

    const perspective = 1 / (1 + z2 * 0.18);
    const scale = Math.min(width, height) * view.zoom * perspective;

    return {
      x: width * 0.56 + x1 * scale,
      y: height * 0.61 - y2 * scale,
      depth: z2
    };
  }

  function drawLine(ctx, a, b) {
    ctx.beginPath();
    ctx.moveTo(a.x, a.y);
    ctx.lineTo(b.x, b.y);
    ctx.stroke();
  }

  function fitText(ctx, text, maxWidth) {
    const source = String(text || "");
    if (ctx.measureText(source).width <= maxWidth) return source;

    let clipped = source;
    while (clipped.length > 4 && ctx.measureText(`${clipped}...`).width > maxWidth) {
      clipped = clipped.slice(0, -1);
    }

    return `${clipped}...`;
  }

  function drawFrame(ctx, projectPoint, yMin, yMax) {
    const corners = [
      { x: -1, z: -1, y: yMin },
      { x: 1, z: -1, y: yMin },
      { x: 1, z: 1, y: yMin },
      { x: -1, z: 1, y: yMin },
      { x: -1, z: -1, y: yMax },
      { x: 1, z: -1, y: yMax },
      { x: 1, z: 1, y: yMax },
      { x: -1, z: 1, y: yMax }
    ].map(projectPoint);

    ctx.save();
    ctx.strokeStyle = "rgba(15, 23, 42, 0.28)";
    ctx.lineWidth = 1;
    ctx.setLineDash([2, 7]);

    [
      [0, 1], [1, 2], [2, 3], [3, 0],
      [4, 5], [5, 6], [6, 7], [7, 4],
      [0, 4], [1, 5], [2, 6], [3, 7]
    ].forEach(([a, b]) => drawLine(ctx, corners[a], corners[b]));

    for (let i = 1; i < 5; i += 1) {
      const u = -1 + i * 0.4;
      drawLine(ctx, projectPoint({ x: u, z: -1, y: yMin }), projectPoint({ x: u, z: 1, y: yMin }));
      drawLine(ctx, projectPoint({ x: -1, z: u, y: yMin }), projectPoint({ x: 1, z: u, y: yMin }));
      const y = yMin + ((yMax - yMin) * i) / 5;
      drawLine(ctx, projectPoint({ x: -1, z: -1, y }), projectPoint({ x: -1, z: 1, y }));
    }

    ctx.restore();
  }

  function drawAxes(ctx, projectPoint, config, yMin, yMax) {
    const origin = projectPoint({ x: -1, z: -1, y: yMin });
    const xEnd = projectPoint({ x: 1.12, z: -1, y: yMin });
    const zEnd = projectPoint({ x: -1, z: 1.12, y: yMin });
    const yEnd = projectPoint({ x: -1, z: -1, y: yMax });

    ctx.save();
    ctx.setLineDash([]);
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.strokeStyle = "rgba(2, 6, 23, 0.92)";
    ctx.lineWidth = 2.4;
    drawLine(ctx, origin, xEnd);
    drawLine(ctx, origin, zEnd);
    drawLine(ctx, origin, yEnd);

    ctx.fillStyle = "#020617";
    ctx.font = "800 13px system-ui, sans-serif";
    ctx.fillText(config.xTitle || "x", xEnd.x + 6, xEnd.y + 4);
    ctx.fillText(config.zTitle || "z", zEnd.x + 6, zEnd.y + 4);
    ctx.fillText(config.yTitle || "y", yEnd.x - 18, yEnd.y - 10);

    ctx.font = "12px system-ui, sans-serif";
    ctx.fillStyle = "#1e293b";
    const yTicks = 4;
    for (let i = 0; i <= yTicks; i += 1) {
      const yValue = yMin + ((yMax - yMin) * i) / yTicks;
      const tick = projectPoint({ x: -1, z: -1, y: yValue });
      const tickEnd = projectPoint({ x: -1.04, z: -1, y: yValue });
      ctx.strokeStyle = "rgba(2, 6, 23, 0.76)";
      ctx.lineWidth = 1.3;
      drawLine(ctx, tick, tickEnd);
      ctx.fillText(yValue.toFixed(2), clamp(tickEnd.x - 42, 6, 58), tickEnd.y + 4);
    }

    const xLabels = config.xLabels || [];
    const zLabels = config.zLabels || [];
    const xLast = xLabels.length - 1;
    const zLast = zLabels.length - 1;

    [[0, xLabels[0]], [xLast, xLabels[xLast]]].forEach(([index, label]) => {
      if (label === undefined || xLast <= 0) return;
      const u = -1 + (2 * index) / xLast;
      const p = projectPoint({ x: u, z: -1, y: yMin });
      ctx.fillText(String(label), p.x - 6, p.y + 18);
    });

    [[0, zLabels[0]], [zLast, zLabels[zLast]]].forEach(([index, label]) => {
      if (label === undefined || zLast <= 0) return;
      const u = -1 + (2 * index) / zLast;
      const p = projectPoint({ x: -1, z: u, y: yMin });
      ctx.fillText(String(label), p.x - 18, p.y + 18);
    });

    ctx.restore();
  }

  function drawColorBar(ctx, width, yMin, yMax) {
    const barX = width - 50;
    const barY = 76;
    const barW = 12;
    const barH = 190;

    for (let i = 0; i < barH; i += 1) {
      const value = yMin + ((barH - i) / barH) * (yMax - yMin);
      ctx.fillStyle = valueColor(value, yMin, yMax);
      ctx.fillRect(barX, barY + i, barW, 1);
    }

    ctx.strokeStyle = "#64748b";
    ctx.strokeRect(barX, barY, barW, barH);
    ctx.fillStyle = "#334155";
    ctx.font = "11px system-ui, sans-serif";
    ctx.fillText(yMax.toFixed(2), barX + 18, barY + 4);
    ctx.fillText(yMin.toFixed(2), barX + 18, barY + barH);
  }

  function render(canvas) {
    if (!canvas.isConnected) return;

    const config = getConfig(canvas);
    const rect = canvas.getBoundingClientRect();
    const width = Math.max(280, Math.floor(rect.width));
    const height = Math.max(260, Math.floor(rect.height));
    const ratio = window.devicePixelRatio || 1;

    canvas.width = Math.floor(width * ratio);
    canvas.height = Math.floor(height * ratio);
    const ctx = canvas.getContext("2d");
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = "#ffffff";
    ctx.fillRect(0, 0, width, height);

    const current = state.get(canvas) || {};
    const view = {
      azimuth: current.azimuth ?? DEFAULT_VIEW.azimuth,
      elevation: current.elevation ?? DEFAULT_VIEW.elevation,
      zoom: current.zoom ?? DEFAULT_VIEW.zoom
    };

    const yMin = Number.isFinite(config.yMin) ? config.yMin : 0;
    const yMax = Number.isFinite(config.yMax) ? config.yMax : 1;
    const surface = buildSurface(config);

    if (!surface.points.length) {
      ctx.fillStyle = "#64748b";
      ctx.font = "14px system-ui, sans-serif";
      ctx.fillText("Нет данных для 3D-графика", 24, 36);
      return;
    }

    const projectPoint = (point) => project(point, view, width, height, yMin, yMax);
    ctx.fillStyle = "#111827";
    ctx.font = "700 15px system-ui, sans-serif";
    if (config.title) {
      ctx.fillText(fitText(ctx, config.title, Math.max(120, width - 92)), 18, 26);
    }

    drawFrame(ctx, projectPoint, yMin, yMax);

    const faces = [];
    for (let z = 0; z < surface.zSteps - 1; z += 1) {
      for (let x = 0; x < surface.xSteps - 1; x += 1) {
        const points = [
          surface.points[z][x],
          surface.points[z][x + 1],
          surface.points[z + 1][x + 1],
          surface.points[z + 1][x]
        ];
        const projected = points.map(projectPoint);
        faces.push({
          projected,
          value: points.reduce((sum, point) => sum + point.y, 0) / 4,
          depth: projected.reduce((sum, point) => sum + point.depth, 0) / 4
        });
      }
    }

    faces.sort((a, b) => b.depth - a.depth);
    faces.forEach((face) => {
      ctx.beginPath();
      ctx.moveTo(face.projected[0].x, face.projected[0].y);
      for (let i = 1; i < face.projected.length; i += 1) {
        ctx.lineTo(face.projected[i].x, face.projected[i].y);
      }
      ctx.closePath();
      ctx.fillStyle = valueColor(face.value, yMin, yMax);
      ctx.globalAlpha = 0.96;
      ctx.fill();
      ctx.globalAlpha = 1;
      ctx.strokeStyle = "rgba(15, 23, 42, 0.28)";
      ctx.lineWidth = 0.45;
      ctx.stroke();
    });

    drawAxes(ctx, projectPoint, config, yMin, yMax);
    drawColorBar(ctx, width, yMin, yMax);
    state.set(canvas, { ...current, ...view, surface });
  }

  function attach(canvas) {
    if (canvas.dataset.surfaceAttached === "true") return;
    canvas.dataset.surfaceAttached = "true";
    canvas.style.cursor = "grab";
    canvas.style.touchAction = "none";
    canvas.style.userSelect = "none";

    const rect = canvas.getBoundingClientRect();
    const initialZoom = rect.width < 420 ? 0.25 : DEFAULT_VIEW.zoom;
    state.set(canvas, { ...DEFAULT_VIEW, zoom: initialZoom, dragging: false });
    render(canvas);

    canvas.addEventListener("pointerdown", (event) => {
      const current = state.get(canvas);
      state.set(canvas, { ...current, dragging: true, lastX: event.clientX, lastY: event.clientY });
      canvas.setPointerCapture(event.pointerId);
      canvas.style.cursor = "grabbing";
    });

    canvas.addEventListener("pointermove", (event) => {
      const current = state.get(canvas);
      if (!current || !current.dragging) return;

      const dx = event.clientX - current.lastX;
      const dy = event.clientY - current.lastY;
      state.set(canvas, {
        ...current,
        azimuth: current.azimuth + dx * 0.01,
        elevation: clamp(current.elevation + dy * 0.008, -1.25, -0.18),
        lastX: event.clientX,
        lastY: event.clientY
      });
      render(canvas);
    });

    const stopDrag = (event) => {
      const current = state.get(canvas);
      if (!current) return;
      state.set(canvas, { ...current, dragging: false });
      canvas.style.cursor = "grab";
      if (event.pointerId !== undefined) {
        try {
          canvas.releasePointerCapture(event.pointerId);
        } catch (_error) {}
      }
    };

    canvas.addEventListener("pointerup", stopDrag);
    canvas.addEventListener("pointercancel", stopDrag);

    canvas.addEventListener(
      "wheel",
      (event) => {
        event.preventDefault();
        const current = state.get(canvas);
        if (!current) return;

        state.set(canvas, {
          ...current,
          zoom: clamp(current.zoom - event.deltaY * 0.00035, 0.22, 0.62)
        });
        render(canvas);
      },
      { passive: false }
    );

    canvas.addEventListener("dblclick", () => {
      const freshRect = canvas.getBoundingClientRect();
      const freshZoom = freshRect.width < 420 ? 0.25 : DEFAULT_VIEW.zoom;
      state.set(canvas, { ...DEFAULT_VIEW, zoom: freshZoom, dragging: false });
      canvas.style.cursor = "grab";
      render(canvas);
    });
  }

  function init() {
    document.querySelectorAll(".js-surface-chart").forEach(attach);
  }

  function rerenderAll() {
    document.querySelectorAll(".js-surface-chart").forEach(render);
  }

  window.addEventListener("resize", rerenderAll);
  document.addEventListener("turbo:load", init);

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
