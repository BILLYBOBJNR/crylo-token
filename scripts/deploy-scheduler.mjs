import { ethers } from "hardhat";

async function main() {
  const TICKET = process.env.TICKET_ADDRESS;      // set in env before running
  const FIRST   = Number(process.env.FIRST_DRAW_TS);

  if (!TICKET || !FIRST) throw new Error("Set TICKET_ADDRESS and FIRST_DRAW_TS env vars");

  const Sched = await ethers.getContractFactory("CryloDrawScheduler");
  const sched = await Sched.deploy(TICKET, FIRST);
  await sched.waitForDeployment();

  const addr = await sched.getAddress();
  console.log("Scheduler deployed:", addr);
}

main().catch((e) => { console.error(e); process.exit(1); });
