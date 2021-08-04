var path = require("path");
var Config = artifacts.require("Config");
var BigNumber = require("bignumber.js");

module.exports = async function (deployer, network) {
    network = /([a-z]+)(-fork)?/.exec(network)[1];
    var deployConfig = require(path.join(
        path.dirname(__dirname),
        "deploy-config.js"
    ))[network];
    var config = await Config.deployed();

    for (let i = 0; i < deployConfig.tokens.length; ++i) {
        let token = deployConfig.tokens[i];

        var hasToken = await config.hasToken(token.address);
        if (!hasToken) {
            console.log(`Config.addToken(token = ${token.address})`);
            await config.addToken(token.address);
        }

        let bade = BigNumber(token.bade)
            .multipliedBy(1e18)
            .dividedBy(100)
            .toFixed();

        let aade = BigNumber(token.aade)
            .multipliedBy(1e18)
            .dividedBy(100)
            .toFixed();

        let fade = BigNumber(token.fade)
            .multipliedBy(1e18)
            .dividedBy(100)
            .toFixed();

        console.log(
            `config.setades(token = ${token.address}, bade = ${bade}, aade = ${aade}, fade = ${fade})`
        );
        await config.setAdes(token.address, bade, aade, fade);

        let line = BigNumber(token.line).multipliedBy(1e18).toFixed();
        console.log(`config.setLine(token = ${token.address}, line = ${line})`);
        await config.setLine(token.address, line);
    }

    console.log(`config.setStep(step = ${deployConfig.step}`);
    await config.setStep(deployConfig.step);

    console.log(`config.setGade(gade = ${deployConfig.gade})`);
    await config.setGade(deployConfig.gade);

    console.log(`config.setOracle(oracle = ${deployConfig.oracle})`);
    await config.setOracle(deployConfig.oracle);

    console.log(`config.setMintFee(fee = ${deployConfig.mintFee})`);
    await config.setMintFee(deployConfig.mintFee);

    console.log(`config.setFeeRecipient(fee = ${deployConfig.feeRecipient})`);
    await config.setFeeRecipient(deployConfig.feeRecipient);
};
