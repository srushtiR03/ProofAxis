const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  // Read configuration from deploy.json
  const configPath = path.join(__dirname, "../deploy.json");
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

  console.log("=====================================");
  console.log(`🚀 Deploying Project: ${config.projectName}`);
  console.log(`🌐 Network: ${config.network}`);
  console.log("=====================================\n");

  // Compile contracts
  console.log("🧱 Compiling smart contracts...");
  await hre.run("compile");

  // Get contract factory
  const ContractFactory = await hre.ethers.getContractFactory(config.deployment.contractName);

  // Deploy contract
  console.log(`📦 Deploying ${config.deployment.contractName}...`);
  const contract = await ContractFactory.deploy();

  await contract.waitForDeployment();

  const contractAddress = await contract.getAddress();
  console.log(`✅ ${config.deployment.contractName} deployed successfully!`);
  console.log(`📍 Contract Address: ${contractAddress}\n`);

  // Update deployment info in deploy.json
  config.deployment.contractAddress = contractAddress;
  config.deployment.deploymentDate = new Date().toISOString();

  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log("📝 Updated deploy.json with deployment details.\n");

  // Optional: Verify contract on Etherscan if enabled
  if (config.verification.verifyOnEtherscan && config.verification.etherscanApiKey) {
    console.log("🔍 Verifying contract on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: contractAddress,
        constructorArguments: []
      });
      console.log("✅ Contract verified successfully!");
    } catch (error) {
      console.log("⚠️ Verification failed (possibly already verified):", error.message);
    }
  }

  console.log("🎉 Deployment complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
