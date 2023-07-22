// import { WagmiConfig, createClient, chain } from "wagmi";
// import { ConnectKitProvider, getDefaultClient } from "connectkit";
import { EthereumClient, w3mConnectors, w3mProvider } from '@web3modal/ethereum'
import { Web3Modal } from '@web3modal/react'
import { configureChains, createConfig, WagmiConfig } from 'wagmi'

import { arbitrum, mainnet, polygon } from 'wagmi/chains'

const alchemyId = process.env.ALCHEMY_ID;

// Choose which chains you'd like to show
// const chains = [chain.mainnet, chain.goerli, chain.optimism, chain.arbitrum];
const chains = [arbitrum, mainnet, polygon]


const projectId= '7456c703c74d537c68c7168607faeb5b';
const { publicClient } = configureChains(chains, [w3mProvider({ projectId })]);

// const wagmiConfig = createConfig({
//   autoConnect: true,
//   connectors: w3mConnectors({ projectId, chains }),
//   publicClient
// });

const wagmiConfig = createConfig({
  autoConnect: true,
  connectors: w3mConnectors({ projectId, chains }),
  publicClient
})
const ethereumClient = new EthereumClient(wagmiConfig, chains)

// const client = createClient(
//   getDefaultClient({

//     appName: "App",
//     alchemyId,
//     chains,
//   }),
// );

export function Page({ children }) {
  return (
    <>
    <WagmiConfig config={wagmiConfig}>
        {children}
    </WagmiConfig>
    <Web3Modal projectId={projectId} ethereumClient={ethereumClient} />
    </> 

  );
};