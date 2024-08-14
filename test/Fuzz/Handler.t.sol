//SPDX-LLicense-Identifier: MIT

pragma solidity 0.8.20;
import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {TSwapPool} from "../../script/DeployTSwap.t.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";


contract Handler{}