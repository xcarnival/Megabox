var path = require("path");
var Config = artifacts.require("Config");
var BigNumber = require("bignumber.js");


module.exports = async function (deployer, network) {
    network = /([a-z]+)(-fork)?/.exec(network)[1];
    var deployConfig = require(path.join(path.dirname(__dirname), "deploy-config.json"))[network];
    var config = await Config.deployed();

    // for (let i = 0; i < deployConfig.tokens.length; ++i) {
    //     let token = deployConfig.tokens[i];

    //     var hasToken = await config.hasToken(token.address);
    //     if (!hasToken) {
    //         console.log(`Config.addToken(token = ${token.address})`);
    //         await config.addToken(token.address);
    //     }

    //     let bade = BigNumber(token.bade)
    //         .multipliedBy(1e18)
    //         .dividedBy(100)
    //         .toFixed();

    //     let aade = BigNumber(token.aade)
    //         .multipliedBy(1e18)
    //         .dividedBy(100)
    //         .toFixed();

    //     let fade = BigNumber(token.fade)
    //         .multipliedBy(1e18)
    //         .dividedBy(100)
    //         .toFixed();

    //     console.log(
    //         `config.setades(token = ${token.address}, bade = ${bade}, aade = ${aade}, fade = ${fade})`
    //     );
    //     await config.setAdes(token.address, bade, aade, fade);

    //     let line = BigNumber(token.line).multipliedBy(1e18).toFixed();
    //     console.log(`config.setLine(token = ${token.address}, line = ${line})`);
    //     await config.setLine(token.address, line);
    // }

    // var step = BigNumber(deployConfig.step).multipliedBy(1e18).toFixed();

    // console.log(`config.setStep(step = ${step}`);
    // await config.setStep(step);

    var gade = BigNumber(deployConfig.gade)
        .multipliedBy(1e18)
        .dividedBy(100)
        .toFixed();

    console.log(`config.setGade(gade = ${gade})`);
    await config.setGade(gade);

    console.log(`config.setOracle(oracle = ${deployConfig.oracle})`);
    await config.setOracle(deployConfig.oracle);
};
