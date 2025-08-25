async function main() {
  const Test = await ethers.getContractFactory("Test");
  const test = await Test.deploy();
  await test.waitForDeployment(); // ethers v6+
  console.log("Test deployed to:", test.target); // ethers v6+
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

