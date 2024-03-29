module.exports = {
    bsctest: {
        role: {
            admin: "0xfD1412eE517b9eD95E42568603178C4d4CB83E68",
            owner: "0xfD1412eE517b9eD95E42568603178C4d4CB83E68",
            locker: "0xfD1412eE517b9eD95E42568603178C4d4CB83E68",
        },
        tokens: [
            {
                symbol: "BNB",
                address: "0x0000000000000000000000000000000000000000",
                bade: "150",
                aade: "130",
                fade: "115",
                line: "1000000000",
            },
            {
                symbol: "BUSD",
                address: "0x3b1F033dD955f3BE8649Cc9825A2e3E194765a3F",
                bade: "110",
                aade: "105",
                fade: "100",
                line: "2000000000",
            },
            {
                symbol: "USDT",
                address: "0x9Ef8872949858b715c1Bf6C3470cd17337D3bf6F",
                bade: "110",
                aade: "105",
                fade: "100",
                line: "2000000000",
            },
        ],
        step: "10000000000000000000", //10 * 1e18
        oracle: "0xe807f740e0f128250ef048eea07f42552ce6ab1b",
        mintFee: "1000000000000000", //0.1%
        feeRecipient: "0xfD1412eE517b9eD95E42568603178C4d4CB83E68",
    },
    bscmain: {
        role: {
            admin: "0xEDCdB4B5aCDA997B3eC382eDCd1fb49100AF8049",
            owner: "0xB2533E5793D17c90E0687Cdc9e5610b0229B1239",
            locker: "0x02347331742842Cd513974068f50901Efb40e09e",
        },
        tokens: [
            {
                symbol: "BNB",
                address: "0x0000000000000000000000000000000000000000",
                bade: "142.8",
                aade: "138",
                fade: "133",
                line: "2000000",
            },
            {
                symbol: "BUSD",
                address: "0xe9e7cea3dedca5984780bafc599bd69add087d56",
                bade: "117.6",
                aade: "113",
                fade: "111",
                line: "3000000",
            },
            {
                symbol: "ETH",
                address: "0x2170ed0880ac9a755fd29b2688956bd959f933f8",
                bade: "125",
                aade: "120",
                fade: "117.6",
                line: "2000000",
            },
            {
                symbol: "DODO",
                address: "0x67ee3cb086f8a16f34bee3ca72fad36f7db929e2",
                bade: "166",
                aade: "158",
                fade: "153.8",
                line: "500000",
            },
        ],
        step: "100000000000000000000", //100 * 1e18
        oracle: "0xAb6510EfEd4bed584D6ED7a87f3e0A11C5f35328",
        mintFee: "5000000000000000", //0.5%
        feeRecipient: "0x26eEEE04c83B8CFB55D5086Cde011f9f04bEEc4e",
    },
};
