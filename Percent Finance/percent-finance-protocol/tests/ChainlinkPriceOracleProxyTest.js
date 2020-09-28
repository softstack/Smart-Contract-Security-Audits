describe("PriceOracleProxy", () => {
  let root, accounts;
  let oracle;

  beforeEach(async () => {
    [root, ...accounts] = saddle.accounts;

    oracle = await deploy("ChainlinkPriceOracleProxy", [accounts[0]]);
  });

  describe("constructor", () => {
    it("sets address of owner", async () => {
      const configuredAdmin = await call(oracle, "owner");
      expect(configuredAdmin).toEqual(root);
    });

    it("sets address of ethUsdChainlinkAggregatorAddress", async () => {
      const configuredEthUsdChainlinkAggregatorAddress = await call(
        oracle,
        "ethUsdChainlinkAggregatorAddress"
      );
      expect(configuredEthUsdChainlinkAggregatorAddress).toEqual(accounts[0]);
    });
  });

  describe("setEthUsdChainlinkAggregatorAddress", () => {
    it("should set ethUsdChainlinkAggregatorAddress", async () => {
      await send(oracle, "setEthUsdChainlinkAggregatorAddress", [accounts[1]], {
        from: root,
      });
      const configuredEthUsdChainlinkAggregatorAddress = await call(
        oracle,
        "ethUsdChainlinkAggregatorAddress"
      );
      expect(configuredEthUsdChainlinkAggregatorAddress).toEqual(accounts[1]);
    });
    it("should revert if the caller is not owner", async () => {
      await expect(
        send(oracle, "setEthUsdChainlinkAggregatorAddress", [accounts[1]], {
          from: accounts[2],
        })
      ).rejects.toRevert("revert Ownable: caller is not the owner");
    });
  });

  describe("setTokenConfigs", () => {
    it("should set tokenConfigs (single)", async () => {
      await send(
        oracle,
        "setTokenConfigs",
        [[accounts[1]], [accounts[3]], [1], [18]],
        { from: root }
      );
      const configuredTokenConfigs1 = await call(oracle, "tokenConfig", [
        accounts[1],
      ]);
      expect(configuredTokenConfigs1.chainlinkAggregatorAddress).toEqual(
        accounts[3]
      );
      expect(configuredTokenConfigs1.chainlinkPriceBase).toEqual("1");
      expect(configuredTokenConfigs1.underlyingTokenDecimals).toEqual("18");
    });
    it("should set tokenConfigs (multiple)", async () => {
      await send(
        oracle,
        "setTokenConfigs",
        [
          [accounts[1], accounts[2]],
          [accounts[3], accounts[4]],
          [1, 2],
          [18, 6],
        ],
        { from: root }
      );

      const configuredTokenConfigs1 = await call(oracle, "tokenConfig", [
        accounts[1],
      ]);
      expect(configuredTokenConfigs1.chainlinkAggregatorAddress).toEqual(
        accounts[3]
      );
      expect(configuredTokenConfigs1.chainlinkPriceBase).toEqual("1");
      expect(configuredTokenConfigs1.underlyingTokenDecimals).toEqual("18");

      const configuredTokenConfigs2 = await call(oracle, "tokenConfig", [
        accounts[2],
      ]);
      expect(configuredTokenConfigs2.chainlinkAggregatorAddress).toEqual(
        accounts[4]
      );
      expect(configuredTokenConfigs2.chainlinkPriceBase).toEqual("2");
      expect(configuredTokenConfigs2.underlyingTokenDecimals).toEqual("6");
    });
    it("should revert if the caller is not owner", async () => {
      await expect(
        send(
          oracle,
          "setTokenConfigs",
          [[accounts[1]], [accounts[3]], [1], [18]],
          { from: accounts[2] }
        )
      ).rejects.toRevert("revert Ownable: caller is not the owner");
    });
  });

  // Temp
  describe("setTokenConfigs", () => {
    it("should set tokenConfigs (multiple)", async () => {
      await send(
        oracle,
        "setTokenConfigs",
        [
          [accounts[1], accounts[2]],
          [accounts[3], accounts[4]],
          [123, 2],
          [123, 8],
        ],
        { from: root }
      );

      const underlyingPrice2 = await call(oracle, "getUnderlyingPrice", [
        accounts[2],
      ]);
      expect(underlyingPrice2).toEqual("117349399990000000000000000000000");
    });
  });
});
