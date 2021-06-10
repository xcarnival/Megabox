var path = require("path");

var Config = artifacts.require("Config");
var Coin = artifacts.require("Coin");
var Balance = artifacts.require("Balance");
var Asset = artifacts.require("Asset");
var Broker = artifacts.require("Broker");
var Position = artifacts.require("Position");
var Main = artifacts.require("Main");

module.exports = async function (deployer, network) {
    network = /([a-z]+)(-fork)?/.exec(network)[1];

    var deployConfig = require(path.join(path.dirname(__dirname), "deploy-config.json"))[network];

    // var sender = deployer.networks[network].from;
    // console.log("sender: " + sender + "");

    var config = await Config.deployed();
    console.log("confit.initialize");
    await config.initialize(
        deployConfig.role.admin,
        deployConfig.role.owner,
        deployConfig.role.locker
    );

    var broker = await Broker.deployed();
    console.log("broker.initialize");
    await broker.initialize(
        deployConfig.role.admin,
        deployConfig.role.owner,
        Main.address
    );

    var balance = await Balance.deployed();
    console.log("balance.initialize");
    await balance.initialize(deployConfig.role.admin, Main.address);

    var coin = await Coin.deployed();
    console.log("coin.initialize");
    await coin.initialize(
        deployConfig.role.admin,
        Main.address,
        "USDxc Token",
        "USDxc",
        "18"
    );

    var asset = await Asset.deployed();
    console.log("asset.initialize");
    await asset.initialize(deployConfig.role.admin, Main.address);

    var position = await Position.deployed();
    console.log("position.initialize");
    await position.initialize(deployConfig.role.admin, Main.address);

    var main = await Main.deployed();
    console.log("main.initialize");
    await main.initialize(
        Config.address,
        Balance.address,
        Asset.address,
        Coin.address,
        Broker.address,
        Position.address
    );
};
