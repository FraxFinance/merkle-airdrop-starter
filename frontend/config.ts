// Types
type IConfig = {
  decimals: number;
  airdrop: Record<string, number>;
};

// Config from generator
const config: IConfig = {
  "decimals": 18,
  "airdrop": {
    "0x61935F4Ed8050170525dcD54D29847cF46bB38b3": 10,
    "0x3CE4d19C155D977B04C8560Ed1Cc9C6F38Ee3d32": 100
  }
};

// Export config
export default config;
