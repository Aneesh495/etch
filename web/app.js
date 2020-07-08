// Etch EDA: Interactive Web CAD Canvas Engine

(function() {
  let boardData = null;
  let activeNet = null;
  let layerVisibility = {};
  let caliperMode = false;
  let caliperStart = null;

  // View transform state
  let scale = 5.0; // pixels per millimeter
  let panX = 100;
  let panY = 100;
  let isDragging = false;
  let dragStartX = 0;
  let dragStartY = 0;

  const canvas = document.getElementById('cad-canvas');
  const ctx = canvas.getContext('2d');

  function resizeCanvas() {
    canvas.width = canvas.parentElement.clientWidth;
    canvas.height = canvas.parentElement.clientHeight;
    render();
  }

  window.addEventListener('resize', resizeCanvas);

  async function loadBoard() {
    try {
      const res = await fetch('/api/board');
      boardData = await res.json();
      document.getElementById('board-title').textContent =
        `Board: ${boardData.name} (${boardData.stats.widthMm} x ${boardData.stats.heightMm} mm, ${boardData.stats.layerCount}L)`;

      // Initialize layer visibility
      boardData.layers.forEach(l => {
        layerVisibility[l.id] = true;
      });

      populateLayers();
      populateNets();
      resetView();
      render();
    } catch (e) {
      console.error('Failed to load board data:', e);
    }
  }

  function resetView() {
    if (!boardData) return;
    const wPx = boardData.stats.widthMm * scale;
    const hPx = boardData.stats.heightMm * scale;
    panX = (canvas.width - wPx) / 2;
    panY = (canvas.height - hPx) / 2;
    render();
  }

  function populateLayers() {
    const list = document.getElementById('layers-list');
    list.innerHTML = '';
    boardData.layers.forEach(l => {
      const item = document.createElement('div');
      item.className = 'layer-item';
      item.innerHTML = `
        <input type="checkbox" id="chk-${l.id}" checked>
        <div class="layer-swatch" style="background-color: ${l.colorHex}"></div>
        <label for="chk-${l.id}">${l.name} (${l.id})</label>
      `;
      item.querySelector('input').addEventListener('change', (e) => {
        layerVisibility[l.id] = e.target.checked;
        render();
      });
      list.appendChild(item);
    });
  }

  function populateNets() {
    const list = document.getElementById('nets-list');
    list.innerHTML = '';
    boardData.nets.forEach(net => {
      const item = document.createElement('div');
      item.className = 'net-item';
      item.textContent = `${net.name} (${net.pinCount} pins)`;
      item.addEventListener('click', () => {
        if (activeNet === net.id) {
          activeNet = null;
          item.classList.remove('active');
        } else {
          document.querySelectorAll('.net-item').forEach(el => el.classList.remove('active'));
          activeNet = net.id;
          item.classList.add('active');
        }
        render();
      });
      list.appendChild(item);
    });
  }

  function render() {
    if (!boardData) return;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw background grid
    drawGrid();

    ctx.save();
    ctx.translate(panX, panY);

    const wMm = boardData.stats.widthMm;
    const hMm = boardData.stats.heightMm;

    // 1. Board Substrate Outline
    ctx.fillStyle = '#14161d';
    ctx.strokeStyle = '#2f3542';
    ctx.lineWidth = 1;
    ctx.fillRect(0, 0, wMm * scale, hMm * scale);
    ctx.strokeRect(0, 0, wMm * scale, hMm * scale);

    // 2. Traces
    boardData.traces.forEach(trace => {
      if (!layerVisibility[trace.layerId]) return;
      const isHighlighted = (activeNet === null || activeNet === trace.netId);
      ctx.lineWidth = (trace.widthMm || 0.2) * scale;
      ctx.lineCap = 'round';
      ctx.strokeStyle = trace.layerId === 'F.Cu' ? '#ff4757' : '#1e90ff';
      ctx.globalAlpha = isHighlighted ? 1.0 : 0.15;

      ctx.beginPath();
      ctx.moveTo(trace.x1 * scale, (hMm - trace.y1) * scale);
      ctx.lineTo(trace.x2 * scale, (hMm - trace.y2) * scale);
      ctx.stroke();
    });

    // 3. Vias
    ctx.globalAlpha = 1.0;
    boardData.vias.forEach(via => {
      const vx = via.x * scale;
      const vy = (hMm - via.y) * scale;
      const r = (via.diameterMm / 2) * scale;
      const dr = (via.drillDiameterMm / 2) * scale;

      ctx.fillStyle = '#ffa502';
      ctx.beginPath();
      ctx.arc(vx, vy, r, 0, Math.PI * 2);
      ctx.fill();

      ctx.fillStyle = '#08090c';
      ctx.beginPath();
      ctx.arc(vx, vy, dr, 0, Math.PI * 2);
      ctx.fill();
    });

    // 4. Component Pads
    boardData.pads.forEach(pad => {
      if (pad.layerId !== 'All.Cu' && !layerVisibility[pad.layerId]) return;
      const isHighlighted = (activeNet === null || activeNet === pad.netId);
      ctx.globalAlpha = isHighlighted ? 1.0 : 0.2;

      const px = pad.x * scale;
      const py = (hMm - pad.y) * scale;
      const pw = pad.widthMm * scale;
      const ph = pad.heightMm * scale;

      ctx.fillStyle = '#eccc68';
      ctx.fillRect(px - pw / 2, py - ph / 2, pw, ph);

      if (pad.drillDiameterMm > 0) {
        ctx.fillStyle = '#08090c';
        ctx.beginPath();
        ctx.arc(px, py, (pad.drillDiameterMm / 2) * scale, 0, Math.PI * 2);
        ctx.fill();
      }
    });

    // 5. Silkscreen Labels
    ctx.globalAlpha = 0.9;
    ctx.fillStyle = '#ffffff';
    ctx.font = '10px monospace';
    ctx.textAlign = 'center';
    boardData.components.forEach(comp => {
      const cx = comp.x * scale;
      const cy = (hMm - comp.y) * scale;
      ctx.fillText(comp.refDes, cx, cy - 8);
    });

    ctx.restore();
  }

  function drawGrid() {
    ctx.strokeStyle = '#14161f';
    ctx.lineWidth = 0.5;
    const step = 5 * scale; // 5 mm grid
    ctx.beginPath();
    for (let x = (panX % step); x < canvas.width; x += step) {
      ctx.moveTo(x, 0);
      ctx.lineTo(x, canvas.height);
    }
    for (let y = (panY % step); y < canvas.height; y += step) {
      ctx.moveTo(0, y);
      ctx.lineTo(canvas.width, y);
    }
    ctx.stroke();
  }

  // Mouse pan & zoom handlers
  canvas.addEventListener('mousedown', (e) => {
    isDragging = true;
    dragStartX = e.clientX - panX;
    dragStartY = e.clientY - panY;
  });

  window.addEventListener('mouseup', () => {
    isDragging = false;
  });

  canvas.addEventListener('mousemove', (e) => {
    if (isDragging) {
      panX = e.clientX - dragStartX;
      panY = e.clientY - dragStartY;
      render();
    }
    updateCoordinates(e);
  });

  canvas.addEventListener('wheel', (e) => {
    e.preventDefault();
    const zoomFactor = e.deltaY < 0 ? 1.15 : 0.85;
    const mouseX = e.clientX - canvas.getBoundingClientRect().left;
    const mouseY = e.clientY - canvas.getBoundingClientRect().top;

    panX = mouseX - (mouseX - panX) * zoomFactor;
    panY = mouseY - (mouseY - panY) * zoomFactor;
    scale *= zoomFactor;
    document.getElementById('zoom-display').textContent = `Zoom: ${Math.round(scale * 20)}%`;
    render();
  });

  function updateCoordinates(e) {
    if (!boardData) return;
    const rect = canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left - panX;
    const my = e.clientY - rect.top - panY;

    const xMm = (mx / scale);
    const yMm = boardData.stats.heightMm - (my / scale);
    const xMil = Math.round(xMm * 39.3701);
    const yMil = Math.round(yMm * 39.3701);

    document.getElementById('coord-display').textContent =
      `X: ${xMm.toFixed(2)} mm | Y: ${yMm.toFixed(2)} mm (X: ${xMil} mil | Y: ${yMil} mil)`;
  }

  document.getElementById('btn-reset-view').addEventListener('click', resetView);
  document.getElementById('btn-run-drc').addEventListener('click', async () => {
    const badge = document.getElementById('drc-badge');
    badge.textContent = 'Running DRC...';
    try {
      const res = await fetch('/api/drc');
      const drc = await res.json();
      badge.textContent = drc.passed ? 'DRC: PASS (0 Errors)' : `DRC: FAIL (${drc.errorCount} Errors)`;
      badge.className = drc.passed ? 'badge pass' : 'badge fail';

      const list = document.getElementById('drc-list');
      list.innerHTML = '';
      drc.violations.forEach(v => {
        const item = document.createElement('div');
        item.className = `drc-violation-item ${v.severity.toLowerCase()}`;
        item.textContent = `[${v.severity}] ${v.rule}: ${v.message}`;
        list.appendChild(item);
      });
    } catch (e) {
      badge.textContent = 'DRC Error';
    }
  });

  // Start app
  loadBoard();
})();
