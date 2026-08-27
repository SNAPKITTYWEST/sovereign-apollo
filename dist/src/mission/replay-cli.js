#!/usr/bin/env tsx
import { DeterministicReplay } from "../replay/deterministic.js";
const replay = new DeterministicReplay();
const { frames, finalHash } = replay.replayAll();
console.log(`[REPLAY] ${frames.length} events`);
console.log(`[REPLAY] Final hash: ${finalHash}`);
for (const f of frames.slice(0, 3)) {
    console.log(`  ${f.state.met} ${f.state.vehicle} ${f.state.guidanceMode} hash ${f.hash.slice(0, 12)}...`);
}
console.log("...");
for (const f of frames.slice(-3)) {
    console.log(`  ${f.state.met} ${f.state.vehicle} ${f.state.guidanceMode} hash ${f.hash.slice(0, 12)}...`);
}
if (process.argv.includes("--check-hash")) {
    const ok = DeterministicReplay.verifyDeterminism();
    console.log(ok ? "✓ determinism verified" : "✗ determinism failed");
    process.exit(ok ? 0 : 1);
}
//# sourceMappingURL=replay-cli.js.map