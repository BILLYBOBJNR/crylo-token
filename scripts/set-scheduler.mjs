import { ethers } from "hardhat";

async function main() {
  const TICKET = process.env.TICKET_ADDRESS;
  const SCHED  = process.env.SCHEDULER_ADDRESS;
  if (!TICKET || !SCHED) throw new Error("Set TICKET_ADDRESS and SCHEDULER_ADDRESS");

  const ticket = await ethers.getContractAt("CryloLottoTicket", TICKET);
  const tx = await ticket.setScheduler(SCHED);
  await tx.wait();
  console.log("Scheduler set to:", SCHED);
}
main().catch((e)=>{ console.error(e); process.exit(1); });
