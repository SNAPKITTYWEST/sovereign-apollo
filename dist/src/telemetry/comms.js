/**
 * Communications state machine — RECONSTRUCTED
 */
export class CommsLink {
    state = "ACQUIRE";
    link;
    signalDb = -120;
    constructor(link) { this.link = link; }
    update(signalDb) {
        this.signalDb = signalDb;
        switch (this.state) {
            case "ACQUIRE":
                if (signalDb > -90)
                    this.state = "LOCK";
                break;
            case "LOCK":
                if (signalDb > -85)
                    this.state = "DATA";
                else if (signalDb < -100)
                    this.state = "DROP";
                break;
            case "DATA":
                if (signalDb < -100)
                    this.state = "DROP";
                break;
            case "DROP":
                if (signalDb > -90)
                    this.state = "ACQUIRE";
                break;
        }
    }
}
export class MsfNetwork {
    links = new Map([
        ["GOLDSTONE", new CommsLink("S_BAND")],
        ["HONEYSUCKLE", new CommsLink("S_BAND")],
        ["CARNARVON", new CommsLink("S_BAND")],
    ]);
    route(frame) { /* INFERRED: fan-out to MCC consoles */ return frame; }
}
//# sourceMappingURL=comms.js.map