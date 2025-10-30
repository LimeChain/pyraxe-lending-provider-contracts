import { task } from 'hardhat/config';
import { eContractid, eNetwork } from '../../helpers/types';
import { deployPythOracle, deployFeeCollector } from '../helpers/contracts-deployments';
import { insertContractAddressInDb, getParamPerNetwork } from '../../helpers/contracts-helpers';
import { loadPoolConfig } from '../../helpers/configuration';

task('deploy-pyraxe-pyth-oracle', 'Deploys the Pyraxe Pyth Fallback Oracle')
  .addFlag('verify', 'Verify contract at Etherscan')
  .addParam('pool', 'Pool configuration name')
  .setAction(async ({ verify, pool }, DRE) => {
    await DRE.run('set-DRE');
    const network = <eNetwork>DRE.network.name;
    const poolConfig = loadPoolConfig(pool);

    const { pythAddress, initialStaleTime } = poolConfig.PythOracle[network];

    console.log('-> Deploying Pyraxe Pyth Fallback Oracle...');
    const pythOracle = await deployPythOracle([pythAddress, initialStaleTime], verify);
    await insertContractAddressInDb(eContractid.PythOracle, pythOracle.address);
    console.log(`\tPyth Oracle deployed at: ${pythOracle.address}`);

    return pythOracle.address;
  });

task('deploy-pyraxe-feecollector', 'Deploys the Pyraxe Fee Collector')
  .addFlag('verify', 'Verify contract at Etherscan')
  .addParam('pool', 'Pool configuration name')
  .setAction(async ({ verify, pool }, DRE) => {
    await DRE.run('set-DRE');
    const network = <eNetwork>DRE.network.name;
    const poolConfig = loadPoolConfig(pool);
    const { admin, guardian, withdrawer } = poolConfig.FeeCollector[network];

    console.log('-> Deploying Pyraxe Fee Collector...');
    const feeCollector = await deployFeeCollector([admin, guardian, withdrawer], verify);
    await insertContractAddressInDb(eContractid.FeeCollector, feeCollector.address);
    console.log(`\tFee Collector deployed at: ${feeCollector.address}`);

    return feeCollector.address;
  });
