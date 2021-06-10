var path = require("path");
var upgrades = require('@openzeppelin/truffle-upgrades');
module.exports = async function (deployer, network) {
    network = /([a-z]+)(-fork)?/.exec(network)[1];
    var deployConfig = require(path.join(path.dirname(__dirname), "deploy-config.json"))[network];
    upgrades.admin.transferProxyAdminOwnership(deployConfig.role.admin);
};
