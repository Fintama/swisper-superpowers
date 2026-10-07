/* Mission Control: decision buttons, status lines, and the Open / Decided tabs.
   Copy into the board directory and load it at the end of index.html.
   Page contract: SKILL.md, "Decision cards" and "Tabs".
   Non-ASCII text is \u-escaped: the file is served without a charset. */
(function () {
  var POLL_MS = 20000;
  var TAB_KEY = 'mission-control-tab';

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  function renderStatus(card, ans, ack) {
    var s = card.querySelector('.status');
    if (!s) return;
    if (!ans && !ack) {
      s.className = 'status';
      s.innerHTML = '';
    } else if (!ans) {
      // Settled off-board: say so, or an ack could make an unanswered question vanish.
      s.className = 'status acted';
      s.innerHTML = '\u2705 Answered outside the board \u00b7 PM acted ' + esc(ack.at) + ' \u2014 ' + esc(ack.did);
    } else if (ack) {
      s.className = 'status acted';
      s.innerHTML = '\u2705 You answered \u201c' + esc(ans.answer) + '\u201d \u00b7 ' + esc(ans.at) +
        ' \u00b7 PM acted ' + esc(ack.at) + ' \u2014 ' + esc(ack.did);
    } else {
      s.className = 'status answered';
      s.innerHTML = '\ud83d\udfe1 You answered \u201c' + esc(ans.answer) + '\u201d \u00b7 ' + esc(ans.at) +
        '. The PM has not confirmed acting on it yet.';
    }
  }

  function placeCards(answers, acks) {
    var sink = document.getElementById('decided-cards');
    document.querySelectorAll('.dcard').forEach(function (card) {
      if (!card._home) card._home = card.parentNode;
      var decided = !!answers[card.dataset.id] || !!acks[card.dataset.id];
      if (decided && card.parentNode !== sink) sink.appendChild(card);
      if (!decided && card.parentNode === sink) card._home.appendChild(card);
    });
    document.querySelectorAll('#panel-open h2').forEach(function (h) {
      var n = h.nextElementSibling, live = false;
      while (n && n.tagName !== 'H2') {
        if (n.matches('.dcard, .grid') || n.querySelector('.dcard, .grid')) { live = true; break; }
        n = n.nextElementSibling;
      }
      h.hidden = !live;
    });
    var open = document.querySelectorAll('#panel-open .dcard').length;
    document.getElementById('count-open').textContent = open;
    document.getElementById('count-decided').textContent = sink.querySelectorAll('.dcard').length;
    var empty = document.getElementById('nothing-open');
    if (empty) empty.hidden = open > 0;
  }

  function refresh() {
    return fetch('/state', { cache: 'no-store' })
      .then(function (r) { return r.json(); })
      .then(function (st) {
        var answers = st.answers || {}, acks = st.acks || {};
        document.querySelectorAll('.dcard').forEach(function (card) {
          renderStatus(card, answers[card.dataset.id], acks[card.dataset.id]);
        });
        placeCards(answers, acks);
      })
      .catch(function () { placeCards({}, {}); });
  }

  // The label travels in data-answer, never as text inside a JS call.
  document.querySelectorAll('.dcard button[data-answer]').forEach(function (b) {
    b.addEventListener('click', function (ev) {
      ev.preventDefault();
      var card = b.closest('.dcard');
      fetch('/decide', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: card.dataset.id, answer: b.dataset.answer })
      }).then(refresh);
    });
  });

  function showTab(name) {
    document.querySelectorAll('[id^="panel-"]').forEach(function (p) {
      p.hidden = p.id !== 'panel-' + name;
    });
    document.querySelectorAll('[data-tab]').forEach(function (t) {
      t.classList.toggle('active', t.dataset.tab === name);
    });
    // A browser with site data blocked throws on the accessor itself.
    try { localStorage.setItem(TAB_KEY, name); } catch (e) { /* tab memory is optional */ }
  }

  document.querySelectorAll('[data-tab]').forEach(function (t) {
    t.addEventListener('click', function () { showTab(t.dataset.tab); });
  });
  var saved = null;
  try { saved = localStorage.getItem(TAB_KEY); } catch (e) { /* tab memory is optional */ }
  showTab(saved && document.getElementById('panel-' + saved) ? saved : 'open');

  refresh();
  setInterval(refresh, POLL_MS);
})();
