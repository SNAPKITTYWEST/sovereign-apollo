import { State } from "./state.js";
export interface TimelineEvent {
    seq: number;
    met: string;
    utc: string;
    phase: string;
    event: string;
    vehicle_state: string;
    guidance_mode: string;
    propulsion: string;
    comms: string;
    crew_proc: string;
    fault_state?: string;
}
export declare function loadTimeline(path?: string): TimelineEvent[];
export declare function eventsToStates(events: TimelineEvent[]): State[];
