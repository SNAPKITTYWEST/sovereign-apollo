/**
 * Communications state machine — RECONSTRUCTED
 */
export type CommsState = "ACQUIRE" | "LOCK" | "DATA" | "DROP";
export type LinkType = "S_BAND" | "VHF" | "UHF";
export declare class CommsLink {
    state: CommsState;
    link: LinkType;
    signalDb: number;
    constructor(link: LinkType);
    update(signalDb: number): void;
}
export declare class MsfNetwork {
    links: Map<string, CommsLink>;
    route(frame: any): any;
}
