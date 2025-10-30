import { deployContract, getContract } from '../../helpers/contracts-helpers';
import { tEthereumAddress } from '../../helpers/types';
import { PythFallbackOracle, FeeCollector } from '../../types';

export const deployPythOracle = async (
  args: (string | number)[],
  verify?: boolean
): Promise<PythFallbackOracle> => {
  return deployContract<PythFallbackOracle>('PythFallbackOracle', args);
};

export const deployFeeCollector = async (
  args: string[],
  verify?: boolean
): Promise<FeeCollector> => {
  return deployContract<FeeCollector>('FeeCollector', args);
};

export const getPythOracle = async (address?: tEthereumAddress) =>
  getContract<PythFallbackOracle>('PythFallbackOracle', address as string);

export const getFeeCollector = async (address?: tEthereumAddress) =>
  getContract<FeeCollector>('FeeCollector', address as string);
