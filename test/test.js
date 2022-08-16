const { ethers } = require("hardhat");
describe("Deploying Contract", () => {
  let GovernanceToken, GovernorContract;
  let gtDeploy, gDeploy;
  let deployer, member1, member2, member3, member4;
  beforeEach(async () => {
    [deployer, member1, member2, member3, member4] = await ethers.getSigners();
    GovernanceToken = await ethers.getContractFactory("GovernanceToken");
    gtDeploy = await GovernanceToken.deploy();
    gtDeploy.transfer(member1.address, 50, { from: deployer.address });
    gtDeploy.connect(member1).delegate(member1.address);
    gtDeploy.transfer(member2.address, 50, { from: deployer.address });
    gtDeploy.connect(member2).delegate(member2.address);
    gtDeploy.transfer(member3.address, 50, { from: deployer.address });
    gtDeploy.connect(member3).delegate(member3.address);
    gtDeploy.transfer(member4.address, 50, { from: deployer.address });
    gtDeploy.connect(member4).delegate(member4.address);
    GovernorContract = await ethers.getContractFactory("GovernorContract");
    gDeploy = await GovernorContract.deploy(gtDeploy.address);
    await gtDeploy.transfer(gDeploy.address, 700);
    await gtDeploy.connect(deployer).delegate(deployer.address);
    await gtDeploy.transferOwnership(gDeploy.address, {
      from: deployer.address,
    });
  });

  it("checkingBalance",async()=>{
    const vote = await gtDeploy.connect(deployer).getVotes(deployer.address);
    console.log("voting Power",vote.toString());
  })

});
