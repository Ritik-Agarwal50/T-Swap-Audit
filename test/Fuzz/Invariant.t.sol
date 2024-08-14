//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {TSwapPool} from "../../script/DeployTSwap.t.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";

contract Invariant is StdInvariant, Test {
    ERC20Mock poolToken;
    ERC20Mock weth;

    //assests
    PoolFactory factory;
    TSwapPool pool;

    //Variables
    int256 constant STARTING_X = 100e18;
    int256 constant STARTING_Y = 50e18;

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        //create x nad y bal

        poolToken.mint(address(pool), uint256(STARTING_X));
        weth.mint(address(pool), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        //depositeeeeee

        pool.deposit(
            uint256(STARTING_Y),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp)
        );
    }

    function statefulFuzz_constantProductFormulaStaysTheSame() public {
        //assert();
    }
}
