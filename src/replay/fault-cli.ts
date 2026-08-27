#!/usr/bin/env tsx
import { FaultInjector } from "./fault.js";
import { DeterministicReplay } from "./deterministic.js";
import { Executive } from "../agc/executive.js";

const spec=FaultInjector.fromCli(process.argv);
console.log(`[FAULT-CLI] spec`, spec);
const exec=new Executive();
const injector=new FaultInjector(exec);
const replay=new DeterministicReplay();
injector.inject(spec, replay);
const {frames, finalHash}=replay.replayAll();
console.log(`[FAULT-CLI] replayed ${frames.length} frames, final ${finalHash.slice(0,16)}...`);
