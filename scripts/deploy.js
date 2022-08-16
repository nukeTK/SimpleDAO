const main = async () => {
  const [deployer, member1, member2, member3, member4] =await ethers.getSigners();
  const GovernanceToken = await ethers.getContractFactory("GovernanceToken");
  const gtDeploy = await GovernanceToken.deploy();
  await gtDeploy.transfer(member1.address, 50, { from: deployer.address });
  await gtDeploy.connect(member1).delegate(member1.address);
  await gtDeploy.transfer(member2.address, 50, { from: deployer.address });
  await gtDeploy.connect(member2).delegate(member2.address);
  await gtDeploy.transfer(member3.address, 50, { from: deployer.address });
  await gtDeploy.connect(member3).delegate(member3.address);
  await gtDeploy.transfer(member4.address, 50, { from: deployer.address });
  await gtDeploy.connect(member4).delegate(member4.address);
  const GovernorContract = await ethers.getContractFactory("GovernorContract");
  const gDeploy = await GovernorContract.deploy(gtDeploy.address);
  await gtDeploy.transfer(gDeploy.address, 700);
  await gtDeploy.connect(deployer).delegate(deployer.address);
  await gtDeploy.transferOwnership(gDeploy.address,{from:deployer.address});
  console.log("GovernorContract Address:",gDeploy.address);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });
