/**
 * Executive + Waitlist + Phase Table — DOCUMENTED from EXECUTIVE.agc 1103-1116 etc.
 */
export type JobPriority = 0|1|2|3|4|5|6; // 0 highest

export interface Job {
  id: number;
  priority: JobPriority;
  pc: number; // Z address
  vacArea: number;
  wakeTime?: number; // for WAITLIST
  phase: number; // PHASE TABLE value
}

export class Executive {
  jobs: Job[] = [];
  waitlist: { time: number; job: Job }[] = [];
  phaseTable = new Map<number, number>(); // jobId → phase
  time = 0; // centiseconds
  maxJobs = 8;

  // DOCUMENTED: NOVAC finds free VAC
  novac(priority: JobPriority, pc: number): Job | null {
    if (this.jobs.length >= this.maxJobs) {
      // EXECUTIVE OVERFLOW → 1202 alarm — DOCUMENTED behavior
      throw new ExecOverflowError("1202 Executive Overflow");
    }
    const j: Job = { id: this.jobs.length+1, priority, pc, vacArea: this.jobs.length, phase: 1 };
    this.jobs.push(j);
    // priority queue sort (0 highest) — DOCUMENTED
    this.jobs.sort((a,b)=>a.priority-b.priority);
    return j;
  }

  endOfJob(jobId: number) { this.jobs = this.jobs.filter(j=>j.id!==jobId); }

  // WAITLIST: LONGCALL — DOCUMENTED pp.1117-1132
  longcall(delayCs: number, job: Job) {
    const t = this.time + delayCs;
    this.waitlist.push({ time: t, job });
    this.waitlist.sort((a,b)=>a.time-b.time);
  }

  tick(dtCs=1) { this.time+=dtCs;
    const due = this.waitlist.filter(w=>w.time<=this.time);
    this.waitlist = this.waitlist.filter(w=>w.time>this.time);
    for (const w of due) this.jobs.push(w.job);
  }

  // PHASE TABLE MAINTENANCE — DOCUMENTED pp.1294-1302
  setPhase(jobId:number, phase:number) { this.phaseTable.set(jobId, phase); }
  getPhase(jobId:number){ return this.phaseTable.get(jobId) ?? 0; }
}

export class ExecOverflowError extends Error {
  code = "1202";
  constructor(msg:string){ super(msg); this.name="ExecOverflowError"; }
}

export class RestartManager {
  constructor(private exec: Executive, private tables: Map<number, number>) {}
  /** FRESH_START_AND_RESTART pp.211-237 logic */
  restart(): void {
    // walk RESTART_TABLES pp.238-243 — resume highest phase
    let highest: Job | null=null;
    for (const j of this.exec.jobs) {
      const ph=this.exec.getPhase(j.id);
      if (ph>0 && (!highest || ph> highest.phase)) highest=j;
    }
    if (highest) {
      const pc = this.tables.get(highest.phase) ?? highest.pc;
      highest.pc = pc; // resume at phase point — DOCUMENTED
    }
    // clear overflowed low-priority jobs already thrown
  }
}
