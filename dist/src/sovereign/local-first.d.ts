/**
 * Local-first Mission Control — MODERN DESIGN
 * Offline dashboard + WebDSKY without cloud binding
 */
export interface DashboardConfig {
    port: number;
    offline: boolean;
    dataDir: string;
}
export declare class LocalMissionControl {
    cfg: DashboardConfig;
    constructor(cfg: DashboardConfig);
    start(): void;
    ingestTelemetry(frame: any): void;
    ingestArtifacts(registryPath: string): void;
}
