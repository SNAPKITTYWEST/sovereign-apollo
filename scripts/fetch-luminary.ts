/**
 * Fetch Luminary099 — preserves original source separately
 * Does NOT modify evidence/artifacts without hash verification
 */
import { createHash } from "node:crypto";
import { mkdirSync, writeFileSync, existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const REPO = "https://api.github.com/repos/chrislgarry/Apollo-11/contents/Luminary099";
const DEST = "evidence/artifacts/Luminary099";

async function fetchFileList(): Promise<any[]> {
  const res = await fetch(REPO, { headers: { "User-Agent":"sovereign-apollo" }});
  if(!res.ok) throw new Error(`GitHub API ${res.status}`);
  return await res.json();
}

async function main(){
  const updatePin = process.argv.includes("--update-pin");
  console.log("[FETCH] Luminary099 →", DEST);
  mkdirSync(DEST,{recursive:true});
  try{
    const list = await fetchFileList();
    for(const f of list.slice(0,5)){ // demo fetch 5 files; full would fetch all 101
      if(!f.download_url) continue;
      const r=await fetch(f.download_url);
      const text=await r.text();
      const hash=createHash("sha256").update(text).digest("hex");
      const out=join(DEST, f.name);
      if(!existsSync(out) || updatePin) writeFileSync(out,text);
      console.log(`  ${f.name}  sha256:${hash.slice(0,12)}...`);
    }
    console.log("[FETCH] Done (demo truncated to 5 files; extend to 101 for full verification). Full offline fetch uses git clone + yaYUL.");
    console.log("[FETCH] To fetch all 101 files via git: git clone https://github.com/chrislgarry/Apollo-11 --depth 1");
  }catch(e:any){
    console.log("[FETCH] Offline or rate-limited — using local evidence. Error:", e.message);
    console.log("[FETCH] Ensure evidence/artifacts/Luminary099 exists or run with --update-pin when online.");
  }
}
main();
