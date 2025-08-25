const hre = require("hardhat");

async function main() {
  const CryloLottoTicket = await hre.ethers.getContractFactory("CryloLottoTicket");

  // Use your addresses below:
  const cryloTokenAddress = "0xa7257C85b6cAe0AB1D10eA093f6ADfB0580C4051";
  const devWallet = "0xe5BBde1EcD6bAd426Ba1C992dD50A7cD6fD19449";
  const prizeWallet = "0x9a29DfBd32F28Cc37ebfdbb1331B00A72ef2573C";

  const ticket = await CryloLottoTicket.deploy(
    cryloTokenAddress,
    devWallet,
    prizeWallet
  );

await ticket.waitForDeployment();
console.log("CryloLottoTicket deployed to:", ticket.target || ticket.address);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

