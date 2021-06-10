var { deployProxy } = require("@openzeppelin/truffle-upgrades");

var Config = artifacts.require("Config");
var Coin = artifacts.require("Coin");
var Balance = artifacts.require("Balance");
var Asset = artifacts.require("Asset");
var Broker = artifacts.require("Broker");
var Position = artifacts.require("Position");
var Main = artifacts.require("Main");

var fs = require("fs"),
    path = require("path"),
    util = require('util');

module.exports = async function (deployer, network) {
    network = /([a-z]+)(-fork)?/.exec(network)[1];
    await deployProxy(Config, [], {
        deployer: deployer,
        initializer: false,
        unsafeAllowCustomTypes: true,
    });
    await deployProxy(Coin, [], {
        deployer: deployer,
        initializer: false,
        unsafeAllowCustomTypes: true,
    });
    await deployProxy(Balance, [], {
        deployer: deployer,
        unsafeAllowCustomTypes: true,
        initializer: false,
    });
    await deployProxy(Asset, [], {
        deployer: deployer,
        unsafeAllowCustomTypes: true,
        initializer: false,
    });
    await deployProxy(Broker, [], {
        deployer: deployer,
        unsafeAllowCustomTypes: true,
        initializer: false,
    });
    await deployProxy(Position, [], {
        deployer: deployer,
        unsafeAllowCustomTypes: true,
        initializer: false,
    });
    await deployProxy(Main, [], {
        deployer: deployer,
        unsafeAllowCustomTypes: true,
        initializer: false,
    });

    var output = path.join(path.dirname(__dirname), util.format("deployed_%s.json", Date.now()));
    fs.writeFileSync(
        output,
        JSON.stringify(
            {
                Main: Main.address,
                Position: Position.address,
                Broker: Broker.address,
                Asset: Asset.address,
                Balance: Balance.address,
                Coin: Coin.address,
                Config: Config.address,
            },
            null,
            4
        )
    );
};
