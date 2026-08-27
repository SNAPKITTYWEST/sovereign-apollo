/**
 * Mission Timeline — RECONSTRUCTED deterministic loader
 */
import { readFileSync } from "node:fs";
export function loadTimeline(path = "data/mission_timeline.json") {
    const j = JSON.parse(readFileSync(path, "utf-8"));
    return j.events;
}
export function eventsToStates(events) {
    return events.map(e => {
        const metS = metStrToSec(e.met);
        return {
            met: e.met, metSeconds: metS,
            vehicle: mapVehicle(e.vehicle_state),
            guidanceMode: mapGuidance(e.guidance_mode),
            propulsion: { engine: e.propulsion, thrustN: 0, ispS: 0, throttle: 0, engOn: e.phase === "PDI" || e.phase === "ASCENT" },
            comms: mapComms(e.comms),
            position: [0, 0, 0], velocity: [0, 0, 0], massKg: 15000, dryMassKg: 4000,
            cdu: [0, 0, 0], alarm: e.fault_state
        };
    });
}
function metStrToSec(s) { const [h, m, sec] = s.split(":").map(Number); return h * 3600 + m * 60 + (sec || 0); }
function mapVehicle(s) {
    if (s.includes("stack"))
        return "stack_thrusting";
    if (s.includes("LEO"))
        return "LEO";
    if (s.includes("TLI"))
        return "TLI";
    if (s.includes("surface"))
        return "surface";
    if (s.includes("PDI"))
        return "PDI";
    return "coast";
}
function mapGuidance(s) {
    if (s.includes("P63"))
        return "P63";
    if (s.includes("P64"))
        return "P64";
    if (s.includes("P66"))
        return "P66";
    if (s.includes("IU"))
        return "IU";
    return "PGNCS";
}
function mapComms(s) {
    if (s.includes("VHF"))
        return "VHF";
    if (s.includes("LOS"))
        return "LOS";
    return "MSFN";
}
//# sourceMappingURL=timeline.js.map