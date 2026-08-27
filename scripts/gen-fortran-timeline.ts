import { loadTimeline } from "../src/mission/timeline.js";
import { writeFileSync } from "node:fs";
const ev = loadTimeline();
// Fixed-format for FORTRAN timeline.f: LDTIML reads NEVENT then (CMET IMETSC IVEH IGUID IALARM ICOMM)
// Write file that FORTRAN can READ(10,'(A9,1X,I8,1X,I4,1X,I4,1X,I8,1X,I2)')
let out = `${ev.length}\n`;
for (const e of ev) {
  const metS = (()=>{ const [h,m,s]=e.met.split(":").map(Number); return h*3600+m*60+s; })();
  // Map guidance_mode string to integer flag (Pxx)
  const guidMap: Record<string,number> = { "IU":0, "PGNCS P40":40, "LGC P40":40, "P63 Braking":63, "P63":63, "P64":64, "P66":66, "P68":68, "P12 Ascent Guidance":12, "PGNCS":0, "DAP":0, "IU → PGNCS":0, "LGC P47":47 };
  let iguid = 0;
  for (const [k,v] of Object.entries(guidMap)) if (e.guidance_mode.includes(k)) iguid = v;
  if (e.guidance_mode === "P63 Braking" || e.guidance_mode.includes("P63")) iguid = 63;
  if (e.guidance_mode.includes("P64")) iguid = 64;
  if (e.guidance_mode.includes("P66")) iguid = 66;
  // Vehicle flag
  const vehMap: Record<string,number> = { "stack":0,"LEO":1,"TLI":2,"coast":3,"lunar":4,"PDI":5,"surface":6,"ascent":7,"docked":8,"TEI":9,"reentry":10,"CM":10 };
  let iveh = 3;
  for (const [k,v] of Object.entries(vehMap)) if (e.vehicle_state.toLowerCase().includes(k)) iveh = v;
  if (e.vehicle_state.includes("PDI")) iveh = 5;
  // Comms flag
  let icomm = 0; if (e.comms.includes("LOS")) icomm=3; else if (e.comms.includes("VHF")) icomm=2;
  // Alarm
  let ialarm = 0; if (e.fault_state?.includes("OVERFLOW")) ialarm = 1202; if (e.met==="102:38:22") ialarm=1202;
  // Format: A9 I8 I4 I4 I8 I2  (see timeline.f READ)
  // Pad met to 9 chars (HHH:MM:SS)
  const cmet = e.met.padEnd(9," ");
  out += `${cmet} ${String(metS).padStart(8," ")} ${String(iveh).padStart(4," ")} ${String(iguid).padStart(4," ")} ${String(ialarm).padStart(8," ")} ${String(icomm).padStart(2," ")}\n`;
}
writeFileSync("fortran1978/mission_timeline.txt", out);
writeFileSync("mission_timeline.txt", out);
console.log(`Wrote fortran1978/mission_timeline.txt and mission_timeline.txt with ${ev.length} events`);
console.log(out.split("\n").slice(0,6).join("\n"));
