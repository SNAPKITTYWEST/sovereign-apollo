/**
 * Communications state machine — RECONSTRUCTED
 */

export type CommsState = "ACQUIRE"|"LOCK"|"DATA"|"DROP";
export type LinkType = "S_BAND"|"VHF"|"UHF";

export class CommsLink {
  state: CommsState="ACQUIRE";
  link: LinkType;
  signalDb = -120;
  constructor(link:LinkType){ this.link=link; }
  update(signalDb:number){
    this.signalDb=signalDb;
    switch(this.state){
      case "ACQUIRE": if(signalDb>-90) this.state="LOCK"; break;
      case "LOCK": if(signalDb>-85) this.state="DATA"; else if(signalDb<-100) this.state="DROP"; break;
      case "DATA": if(signalDb<-100) this.state="DROP"; break;
      case "DROP": if(signalDb>-90) this.state="ACQUIRE"; break;
    }
  }
}

export class MsfNetwork {
  links=new Map<string, CommsLink>([
    ["GOLDSTONE", new CommsLink("S_BAND")],
    ["HONEYSUCKLE", new CommsLink("S_BAND")],
    ["CARNARVON", new CommsLink("S_BAND")],
  ]);
  route(frame:any){ /* INFERRED: fan-out to MCC consoles */ return frame; }
}
