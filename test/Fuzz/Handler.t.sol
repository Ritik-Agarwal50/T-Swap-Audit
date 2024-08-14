//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Test, console2} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {TSwapPool} from "../../script/DeployTSwap.t.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    // ghost vars
    int256 public expectedDeltaY;
    int256 public expectedDeltaX;
    int256 startingX;
    int256 startingY;

    int256 public actualDeltaY;
    int256 public actualDeltaX;

    address liquidutyProvider = makeAddr("liquidutyProvider");
    address swapper = makeAddr("swapper");

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(_pool.getWeth());
        poolToken = ERC20Mock(_pool.getPoolToken());
    }

    //depo and swapOut

    function deposit(uint256 wethAmount) public {
        wethAmount = bound(wethAmount, 0, type(uint256).max);
        startingX = int256(poolToken.balanceOf(address(pool)));
        startingY = int256(weth.balanceOf(address(pool)));
        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(
            pool.getPoolTokensToDepositBasedOnWeth(wethAmount)
        );

        //deposit

        vm.startPrank(liquidutyProvider);
        weth.mint(liquidutyProvider, wethAmount);
        poolToken.mint(liquidutyProvider, uint256(expectedDeltaX));
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);

        pool.deposit(
            wethAmount,
            0,
            uint256(expectedDeltaX),
            uint64(block.timestamp)
        );

        //actual
        uint256 endingX = poolToken.balanceOf(address(pool));
        uint256 endingY = weth.balanceOf(address(pool));

        actualDeltaY = int256(endingY) - int256(startingY);
        actualDeltaX = int256(endingX) - int256(startingX);
        vm.stopPrank();
    }

    function swapPoolTokenFOrWethBAsedOnOutputWeth(uint256 outputWeth) public {
        uint256 minWeth = pool.getMinimumWethDepositAmount();
        outputWeth = bound(outputWeth, minWeth, type(uint256).max);
        if (outputWeth >= weth.balanceOf(address(pool))) {
            return;
        }

        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );
        if (poolTokenAmount >= type(uint64).max) {
            return;
        }

        startingX = int256(poolToken.balanceOf(address(pool)));
        startingY = int256(weth.balanceOf(address(pool)));
        expectedDeltaY = int256(-1) * int256(outputWeth);
        expectedDeltaX = int256(
            pool.getPoolTokensToDepositBasedOnWeth(poolTokenAmount)
        );
        if (poolToken.balanceOf(address(swapper)) < poolTokenAmount) {
            poolToken.mint(
                swapper,
                poolTokenAmount - poolToken.balanceOf(swapper) + 1
            );
        }
        vm.startPrank(swapper);
        poolToken.approve(address(pool), type(uint256).max);
        pool.swapExactOutput(
            poolToken,
            weth,
            outputWeth,
            uint64(block.timestamp)
        );
        vm.stopPrank();
        uint256 endingX = poolToken.balanceOf(address(pool));
        uint256 endingY = weth.balanceOf(address(pool));

        actualDeltaY = int256(endingY) - int256(startingY);
        actualDeltaX = int256(endingX) - int256(startingX);
    }
}
