import * as dotenv from 'dotenv'
import { cleanEnv, str } from 'envalid'
import { inspect } from 'util'
import { join } from 'path'
import { writeFile } from 'fs/promises'

import '@nomicfoundation/hardhat-toolbox-viem'
import '@nomicfoundation/hardhat-viem'
import { HardhatUserConfig, task } from 'hardhat/config'
import { TASK_COMPILE_SOLIDITY_EMIT_ARTIFACTS } from 'hardhat/builtin-tasks/task-names'
import { generatePrivateKey } from 'viem/accounts'

dotenv.config()

type ContractMap = Record<string, { abi: object }>

task(TASK_COMPILE_SOLIDITY_EMIT_ARTIFACTS).setAction(
  async (args, env, next) => {
    const output = await next()
    const { artifacts } = env.config.paths
    const promises = Object.entries(args.output.contracts).map(
      async ([sourceName, contract]) => {
        const file = join(artifacts, sourceName, 'abi.ts')
        const { abi } = Object.values(contract as ContractMap)[0]
        const data = `export const abi = ${inspect(abi, false, null)} as const`
        await writeFile(file, data)
      }
    )
    await Promise.all(promises)
    return output
  }
)

const randomPrivateKey = generatePrivateKey()

const { CONTRACT_OWNER_PRIVATE_KEY, ETH_RPC, ETHERSCAN_API_KEY } = cleanEnv(
  process.env,
  {
    CONTRACT_OWNER_PRIVATE_KEY: str({
      default: randomPrivateKey,
    }),
    ETH_RPC: str({ default: '' }),
    ETHERSCAN_API_KEY: str({ default: '' }),
  }
)

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.30',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      outputSelection: {
        '*': {
          '*': ['storageLayout'],
        },
      },
    },
  },
  networks: {
    deploy: {
      url: ETH_RPC,
      accounts: [CONTRACT_OWNER_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
}

export default config
