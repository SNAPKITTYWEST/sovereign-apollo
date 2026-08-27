import { loadTimeline } from "../src/mission/timeline.js";
import { writeFileSync } from "node:fs";
const ev = loadTimeline();
let csv = "seq,met,utc,phase,event,vehicle_state,guidance_mode,propulsion,comms,crew_proc\n";
ev.forEach(e=>{
  csv += `${e.seq},${e.met},${e.utc},${e.phase},"${e.event.replace(/"/g,'""')}",${e.vehicle_state},${e.guidance_mode},"${e.propulsion}",${e.comms},"${e.crew_proc}"\n`;
});
writeFileSync("data/mission_timeline.csv", csv);
console.log(`csv written ${ev.length} rows to data/mission_timeline.csv`);
