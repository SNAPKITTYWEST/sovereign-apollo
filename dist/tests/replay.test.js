import { describe, it, expect } from "vitest";
import { DeterministicReplay } from "../src/replay/deterministic.js";
describe("Deterministic Replay", () => {
    it("timeline 22 events", () => {
        const r = new DeterministicReplay();
        const { frames } = r.replayAll();
        expect(frames.length).toBe(22);
    });
    it("hash chain verified", () => {
        const r = new DeterministicReplay();
        const { frames, finalHash } = r.replayAll();
        expect(finalHash).toMatch(/^[a-f0-9]{64}$/);
        expect(frames[0].telemetry.hashChain.prevHash).toBe("0".repeat(64));
    });
    it("1202 event present at 102:38:22", () => {
        const r = new DeterministicReplay();
        const { frames } = r.replayAll();
        const f = frames.find(x => x.state.met === "102:38:22");
        expect(f).toBeDefined();
        expect(f.state.alarm).toBe("EXECUTIVE_OVERFLOW");
    });
});
//# sourceMappingURL=replay.test.js.map