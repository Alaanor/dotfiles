.pragma library

function boundary(t, i) {
    if (i === 0) return true;
    const p = t[i - 1], c = t[i];
    if (p === " " || p === "-" || p === "_" || p === "." || p === "/" || p === ":" || p === "(") return true;
    return c !== c.toLowerCase() && p === p.toLowerCase();
}

function range(start, length) {
    return Array.from({ length }, (_, k) => start + k);
}

function words(q, text) {
    const t = text.toLowerCase(), m = q.length, n = t.length, none = -1e9;
    const back = [];
    let prev = new Array(n).fill(none);
    for (let j = 0; j < n; j++) if (t[j] === q[0] && boundary(text, j)) prev[j] = 3 - j * 0.1;
    back.push(new Array(n).fill(-1));

    for (let i = 1; i < m; i++) {
        const cur = new Array(n).fill(none), from = new Array(n).fill(-1);
        let best = none, bestAt = -1;
        for (let j = 1; j < n; j++) {
            if (j >= 2 && prev[j - 2] > best) {
                best = prev[j - 2];
                bestAt = j - 2;
            }
            if (t[j] !== q[i]) continue;
            if (prev[j - 1] > none) {
                cur[j] = prev[j - 1] + 4;
                from[j] = j - 1;
            }
            if (bestAt >= 0 && boundary(text, j) && best + 2 > cur[j]) {
                cur[j] = best + 2;
                from[j] = bestAt;
            }
        }
        prev = cur;
        back.push(from);
    }

    let end = -1, score = none;
    for (let j = 0; j < n; j++) if (prev[j] > score) { score = prev[j]; end = j; }
    if (end < 0) return null;

    const positions = new Array(m);
    positions[m - 1] = end;
    for (let i = m - 1; i > 0; i--) positions[i - 1] = back[i][positions[i]];
    return { score: Math.max(1, Math.min(140, 60 + score - n * 0.3)), positions };
}

function match(query, text, fuzzy) {
    const q = query.toLowerCase(), t = (text ?? "").toLowerCase();
    if (q.length === 0) return { score: 0, positions: [] };
    if (q.length > t.length) return null;
    const at = t.indexOf(q);
    if (at === 0) return { score: 320 - Math.min(t.length - q.length, 20), positions: range(0, q.length) };
    if (at > 0) {
        let wordAt = at;
        while (wordAt >= 0 && !boundary(text, wordAt)) wordAt = t.indexOf(q, wordAt + 1);
        if (wordAt > 0) return { score: 240 - Math.min(wordAt, 20), positions: range(wordAt, q.length) };
        return { score: 170 - Math.min(at, 20), positions: range(at, q.length) };
    }
    const compact = q.replace(/\s+/g, "");
    return fuzzy && compact.length > 1 ? words(compact, text) : null;
}
