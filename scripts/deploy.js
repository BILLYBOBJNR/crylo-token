async function main() {
  const CryloToken = await ethers.getContractFactory("CryloToken");
  const crylo = await CryloToken.deploy(
    "0x9a29DfBd32F28Cc37ebfdbb1331B00A72ef2573C", // Prize Pool
    "0xe5BBde1EcD6bAd426Ba1C992dD50A7cD6fD19449", // Dev Wallet
    "0xB1De795118A5a21c2c692A0d263583eCe0A67a0E", // LP Wallet
    "0x10ED43C718714eb63d5aA57B78B54704E256024E", // PancakeSwap Router V2
    "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"  // WBNB
  );
  await crylo.waitForDeployment(); // ethers v6: wait for deploy
  console.log("CRYLO deployed to:", crylo.target); // ethers v6: use .target for address
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

