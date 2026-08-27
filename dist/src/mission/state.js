export function metToString(s) {
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), sec = s % 60;
    return `${String(h).padStart(3, "0")}:${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
}
export function stringToMet(s) {
    const [h, m, sec] = s.split(":").map(Number);
    return h * 3600 + m * 60 + sec;
}
//# sourceMappingURL=state.js.map