export class LocalMissionControl {
    cfg;
    constructor(cfg) { this.cfg = cfg; }
    start() {
        console.log(`[SOVEREIGN] Local MCC starting on port ${this.cfg.port} offline=${this.cfg.offline}`);
        console.log(`[SOVEREIGN] Data dir: ${this.cfg.dataDir}`);
        console.log(`[SOVEREIGN] Routes: /telemetry /timeline /dsky /replay`);
        // In full impl: Electron/web server with WSS to DeterministicReplay
    }
    ingestTelemetry(frame) { }
    ingestArtifacts(registryPath) { }
}
//# sourceMappingURL=local-first.js.map