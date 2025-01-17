---
title: T-Swap Protocol Audit Report
author: Ritik Agarwal
date: Auguest 16, 2024
---

Lead Auditors: 
- Ritik Agarwal

# Table of Contents
- [Table of Contents](#table-of-contents)
- [Protocol Summary](#protocol-summary)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
  - [Roles](#roles)
  - [Issues found](#issues-found)
- [Findings](#findings)
- [High](#high)
  - [\[H-1\] `TSwapPool::deposit` is missing deadline check causing transactions to complete even after the deadline](#h-1-tswappooldeposit-is-missing-deadline-check-causing-transactions-to-complete-even-after-the-deadline)
  - [\[H-2\] Incorrect fee calculation in `TSwapPool::getInputAmountBasedOnOutput` causes protocll to take too many tokens from users, resulting in lost fees](#h-2-incorrect-fee-calculation-in-tswappoolgetinputamountbasedonoutput-causes-protocll-to-take-too-many-tokens-from-users-resulting-in-lost-fees)
  - [\[H-3\] Lack of slippage protection in `TSwapPool::swapExactOutput` causes users to potentially receive way fewer tokens](#h-3-lack-of-slippage-protection-in-tswappoolswapexactoutput-causes-users-to-potentially-receive-way-fewer-tokens)
  - [\[H-4\] `TSwapPool::sellPoolTokens` mismatches input and output tokens causing users to receive the incorrect amount of tokens](#h-4-tswappoolsellpooltokens-mismatches-input-and-output-tokens-causing-users-to-receive-the-incorrect-amount-of-tokens)
  - [\[H-5\] In `TSwapPool::_swap` the extra tokens given to users after every `swapCount` breaks the protocol invariant of `x * y = k`](#h-5-in-tswappool_swap-the-extra-tokens-given-to-users-after-every-swapcount-breaks-the-protocol-invariant-of-x--y--k)
- [Low](#low)
  - [\[L-1\] In `PoolFactory::createPool` function wrong concatenation of strings has been done.](#l-1-in-poolfactorycreatepool-function-wrong-concatenation-of-strings-has-been-done)
  - [\[L-2\] `TSwapPool::deposit` function has unused variable `poolTokenReserves`.](#l-2-tswappooldeposit-function-has-unused-variable-pooltokenreserves)
- [Informational](#informational)
  - [\[I-1\] `PUSH0` is not supported by all chains](#i-1-push0-is-not-supported-by-all-chains)
  - [\[I-2\] In `PoolFactory__PoolDoesNotExist` this custom error is not used anywhere in the contract.](#i-2-in-poolfactory__pooldoesnotexist-this-custom-error-is-not-used-anywhere-in-the-contract)
  - [\[I-3\] `PoolFactory::PoolCreated` Event is missing indexed fields.](#i-3-poolfactorypoolcreated-event-is-missing-indexed-fields)
  - [\[I-4\] In `PoolFactory` contract, constructor is not checking for zero address.](#i-4-in-poolfactory-contract-constructor-is-not-checking-for-zero-address)
  - [\[I-5\]: Large literal values multiples of 10000 can be replaced with scientific notation](#i-5-large-literal-values-multiples-of-10000-can-be-replaced-with-scientific-notation)
  - [\[I-6\] In `TSwapPool` contract, constructor is not checking for zero address.](#i-6-in-tswappool-contract-constructor-is-not-checking-for-zero-address)
  - [\[I-7\] Use of `magic numbers` in TSwapPool::getOutputAmountBasedOnInput\` should be avoided.](#i-7-use-of-magic-numbers-in-tswappoolgetoutputamountbasedoninput-should-be-avoided)

# Protocol Summary

This project is meant to be a permissionless way for users to swap assets between each other at a fair price. You can think of T-Swap as a decentralized asset/token exchange (DEX). 
T-Swap is known as an [Automated Market Maker (AMM)](https://chain.link/education-hub/what-is-an-automated-market-maker-amm) because it doesn't use a normal "order book" style exchange, instead it uses "Pools" of an asset. 
It is similar to Uniswap. To understand Uniswap, please watch this video: [Uniswap Explained](https://www.youtube.com/watch?v=DLu35sIqVTM)

# Disclaimer

The Ritik Agarwal team makes all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit by the team is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the Solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

We use the [CodeHawks](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) severity matrix to determine severity. See the documentation for more details.

# Audit Details 

- Commit Hash: e643a8d4c2c802490976b538dd009b351b1c8dda
- Solc Version: 0.8.20
- Chain(s) to deploy contract to: Ethereum
- Tokens:
  - Any ERC20 token
## Scope 
- In Scope:
```
./src/
#-- PoolFactory.sol
#-- TSwapPool.sol
```

## Roles
- Liquidity Providers: Users who have liquidity deposited into the pools. Their shares are represented by the LP ERC20 tokens. They gain a 0.3% fee every time a swap is made. 
- Users: Users who want to swap tokens.
## Issues found

| Severtity | Number of issues found |
| --------- | ---------------------- |
| High      | 5                      |
| Low       | 2                      |
| Info      | 7                      |
| Total     | 14                     |


# Findings

# High

## [H-1] `TSwapPool::deposit` is missing deadline check causing transactions to complete even after the deadline

**Description:** The `deposit` function accepts a deadline parameter, which according to the documentation is "The deadline for the transaction to be completed by". However, this parameter is never used. As a consequence, operationrs that add liquidity to the pool might be executed at unexpected times, in market conditions where the deposit rate is unfavorable. 

<!-- MEV attacks -->

**Impact:** Transactions could be sent when market conditions are unfavorable to deposit, even when adding a deadline parameter. 

**Proof of Concept:** The `deadline` parameter is unused. 

**Recommended Mitigation:** Consider making the following change to the function.

```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint, // LP tokens -> if empty, we can pick 100% (100% == 17 tokens)
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline
    )
        external
+       revertIfDeadlinePassed(deadline)
        revertIfZero(wethToDeposit)
        returns (uint256 liquidityTokensToMint)
    {
```

## [H-2] Incorrect fee calculation in `TSwapPool::getInputAmountBasedOnOutput` causes protocll to take too many tokens from users, resulting in lost fees

**Description:** The `getInputAmountBasedOnOutput` function is intended to calculate the amount of tokens a user should deposit given an amount of tokens of output tokens. However, the function currently miscalculates the resulting amount. When calculating the fee, it scales the amount by 10_000 instead of 1_000. 

**Impact:** Protocol takes more fees than expected from users. 

**Recommended Mitigation:** 

```diff
    function getInputAmountBasedOnOutput(
        uint256 outputAmount,
        uint256 inputReserves,
        uint256 outputReserves
    )
        public
        pure
        revertIfZero(outputAmount)
        revertIfZero(outputReserves)
        returns (uint256 inputAmount)
    {
-        return ((inputReserves * outputAmount) * 10_000) / ((outputReserves - outputAmount) * 997);
+        return ((inputReserves * outputAmount) * 1_000) / ((outputReserves - outputAmount) * 997);
    }
```

## [H-3] Lack of slippage protection in `TSwapPool::swapExactOutput` causes users to potentially receive way fewer tokens

**Description:** The `swapExactOutput` function does not include any sort of slippage protection. This function is similar to what is done in `TSwapPool::swapExactInput`, where the function specifies a `minOutputAmount`, the `swapExactOutput` function should specify a `maxInputAmount`. 

**Impact:** If market conditions change before the transaciton processes, the user could get a much worse swap. 

**Proof of Concept:** 
1. The price of 1 WETH right now is 1,000 USDC
2. User inputs a `swapExactOutput` looking for 1 WETH
   1. inputToken = USDC
   2. outputToken = WETH
   3. outputAmount = 1
   4. deadline = whatever
3. The function does not offer a maxInput amount
4. As the transaction is pending in the mempool, the market changes! And the price moves HUGE -> 1 WETH is now 10,000 USDC. 10x more than the user expected
5. The transaction completes, but the user sent the protocol 10,000 USDC instead of the expected 1,000 USDC 

**Recommended Mitigation:** We should include a `maxInputAmount` so the user only has to spend up to a specific amount, and can predict how much they will spend on the protocol. 

```diff
    function swapExactOutput(
        IERC20 inputToken, 
+       uint256 maxInputAmount,
.
.
.
        inputAmount = getInputAmountBasedOnOutput(outputAmount, inputReserves, outputReserves);
+       if(inputAmount > maxInputAmount){
+           revert();
+       }        
        _swap(inputToken, inputAmount, outputToken, outputAmount);
```

## [H-4] `TSwapPool::sellPoolTokens` mismatches input and output tokens causing users to receive the incorrect amount of tokens

**Description:** The `sellPoolTokens` function is intended to allow users to easily sell pool tokens and receive WETH in exchange. Users indicate how many pool tokens they're willing to sell in the `poolTokenAmount` parameter. However, the function currently miscalculaes the swapped amount. 

This is due to the fact that the `swapExactOutput` function is called, whereas the `swapExactInput` function is the one that should be called. Because users specify the exact amount of input tokens, not output. 

**Impact:** Users will swap the wrong amount of tokens, which is a severe disruption of protcol functionality. 

**Proof of Concept:** 
<write PoC here>

**Recommended Mitigation:** 

Consider changing the implementation to use `swapExactInput` instead of `swapExactOutput`. Note that this would also require changing the `sellPoolTokens` function to accept a new parameter (ie `minWethToReceive` to be passed to `swapExactInput`)

```diff
    function sellPoolTokens(
        uint256 poolTokenAmount,
+       uint256 minWethToReceive,    
        ) external returns (uint256 wethAmount) {
-        return swapExactOutput(i_poolToken, i_wethToken, poolTokenAmount, uint64(block.timestamp));
+        return swapExactInput(i_poolToken, poolTokenAmount, i_wethToken, minWethToReceive, uint64(block.timestamp));
    }
```

Additionally, it might be wise to add a deadline to the function, as there is currently no deadline. (MEV later)

## [H-5] In `TSwapPool::_swap` the extra tokens given to users after every `swapCount` breaks the protocol invariant of `x * y = k`

**Description:** The protocol follows a strict invariant of `x * y = k`. Where:
- `x`: The balance of the pool token
- `y`: The balance of WETH
- `k`: The constant product of the two balances

This means, that whenever the balances change in the protocol, the ratio between the two amounts should remain constant, hence the `k`. However, this is broken due to the extra incentive in the `_swap` function. Meaning that over time the protocol funds will be drained. 

The follow block of code is responsible for the issue. 

```javascript
        swap_count++;
        if (swap_count >= SWAP_COUNT_MAX) {
            swap_count = 0;
            outputToken.safeTransfer(msg.sender, 1_000_000_000_000_000_000);
        }
```

**Impact:** A user could maliciously drain the protocol of funds by doing a lot of swaps and collecting the extra incentive given out by the protocol. 

Most simply put, the protocol's core invariant is broken. 

**Proof of Concept:** 
1. A user swaps 10 times, and collects the extra incentive of `1_000_000_000_000_000_000` tokens
2. That user continues to swap untill all the protocol funds are drained

<details>
<summary>Proof Of Code</summary>

Place the following into `TSwapPool.t.sol`.

```javascript

    function testInvariantBroken() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        uint256 outputWeth = 1e17;

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);
        poolToken.mint(user, 100e18);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));

        int256 startingY = int256(weth.balanceOf(address(pool)));
        int256 expectedDeltaY = int256(-1) * int256(outputWeth);

        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(pool));
        int256 actualDeltaY = int256(endingY) - int256(startingY);
        assertEq(actualDeltaY, expectedDeltaY);
    }
```

</details>

**Recommended Mitigation:** Remove the extra incentive mechanism. If you want to keep this in, we should account for the change in the x * y = k protocol invariant. Or, we should set aside tokens in the same way we do with fees. 

```diff
-        swap_count++;
-        // Fee-on-transfer
-        if (swap_count >= SWAP_COUNT_MAX) {
-            swap_count = 0;
-            outputToken.safeTransfer(msg.sender, 1_000_000_000_000_000_000);
-        }
```

# Low

## [L-1] In `PoolFactory::createPool` function wrong concatenation of strings has been done.

**Description** In `PoolFactory::createPool` function, wrong concatenation of strings has been done. In `liquidityTokenSymbol` variable we are concatenating `ts` symbol with the `.name()` function which is wrong, we have to use `.symbol()` function instead of `.name()` function.

**Impact** It will not affect the functionality of the contract but it will affect the readability of the contract.

**Proof of Concept:**
<detials>

```diff
        string memory liquidityTokenSymbol = string.concat(
            "ts",
-            IERC20(tokenAddress).name()
        );

        string memory liquidityTokenSymbol = string.concat(
            "ts",
+            IERC20(tokenAddress).symbol()
        );
```

</details>

## [L-2] `TSwapPool::deposit` function has unused variable `poolTokenReserves`.

**Description** In `TSwapPool::deposit` function, `poolTokenReserves` variable is declared but not used anywhere in the function. It is recommended to remove the unused variable to reduce the contract size and gas cost.

**Impact** It will not affect the functionality of the contract but it will affect the readability of the contract.

**Proof of Concept**

<details>

```diff
-            uint256 poolTokenReserves = i_poolToken.balanceOf(address(this));
```
</details>

# Informational

## [I-1] `PUSH0` is not supported by all chains

**Description:** Solc compiler version 0.8.20 switches the default target EVM version to Shanghai, which means that the generated bytecode will include PUSH0 opcodes. Be sure to select the appropriate EVM version in case you intend to deploy on a chain other than mainnet like L2 chains that may not support PUSH0, otherwise deployment of your contracts will fail.

**Recommended Mitigation:** Use the appropriate EVM version for your deployment target.

**Impact** It might affect the contract in future if you try to deploy on any other L2.

 <details><summary>2 Found Instances</summary>
 
 
 - Found in src/PoolFactory.sol [Line: 15](src/PoolFactory.sol#L15)
 
 	```solidity
 	pragma solidity 0.8.20;
 	```
 
 - Found in src/TSwapPool.sol [Line: 15](src/TSwapPool.sol#L15)
 
 	```solidity
 	pragma solidity 0.8.20;
 	```
 
 </details>
 
  ## [I-2] In `PoolFactory__PoolDoesNotExist` this custom error is not used anywhere in the contract.
 **Description:** `PoolFactory__PoolDoesNotExist` is not used any any where in the contract it is recommended to remove it. This  will reduce the contract size and gas cost. It wil also make the contract more readable.
 
 <details><summary>1 Found Instances</summary>
 
 
 - Found in src/PoolFactory.sol [Line: 22](src/PoolFactory.sol#L22)
 
 	```solidity
 	    error PoolFactory__PoolDoesNotExist(address tokenAddress);
 	```
 
 </details>
 
 
  ## [I-3] `PoolFactory::PoolCreated` Event is missing indexed fields.
 **Description** Index event fields make the field more quickly accessible to off-chain tools that parse events. However, note  that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event  (three fields). Each event should use three indexed fields if there are three or more fields, and gas usage is not particularly  of concern for the events in question. If there are fewer than three fields, all of the fields should be indexed.
 
 <details><summary>4 Found Instances</summary>
 
 
 - Found in src/PoolFactory.sol [Line: 35](src/PoolFactory.sol#L35)
 
 	```solidity
 	    event PoolCreated(address tokenAddress, address poolAddress);
 	```
 
 - Found in src/TSwapPool.sol [Line: 52](src/TSwapPool.sol#L52)
 
 	```solidity
 	    event LiquidityAdded(
 	```
 
 - Found in src/TSwapPool.sol [Line: 57](src/TSwapPool.sol#L57)
 
 	```solidity
 	    event LiquidityRemoved(
 	```
 
 - Found in src/TSwapPool.sol [Line: 62](src/TSwapPool.sol#L62)
 
 	```solidity
 	    event Swap(
 	```
 
 </details>
 
  ## [I-4] In `PoolFactory` contract, constructor is not checking for zero address.
 **Description:** In the constructor of `PoolFactory` contract, it is not checking for zero address. It is recommended to check  for zero address before deploying the contract.
 
 
 <details><summary>1 Found Instances</summary>
 
 - Found in src/PoolFactory.sol [Line: 43](src/PoolFactory.sol#L43)
 
 	```solidity
     constructor(address wethToken) {
         
         i_wethToken = wethToken;
     }
 	```
 </details>

## [I-5]: Large literal values multiples of 10000 can be replaced with scientific notation

**Description**Use `e` notation, for example: `1e18`, instead of its full numeric value.

```diff
-	    uint256 private constant MINIMUM_WETH_LIQUIDITY = 1_000_000_000;
+       uint256 private constant MINIMUM_WETH_LIQUIDITY = 1e9;
```

## [I-6] In `TSwapPool` contract, constructor is not checking for zero address.

**Description:** In the constructor of `TSwapPool` contract, it is not checking for zero address. It is recommended to check for zero address before deploying the contract.

 <details><summary>1 Found Instances</summary>
 
 - Found in src/TSwapPool.sol [Line: 92](src/TSwapPool.sol#L92)
 
 	```solidity
    constructor(
        address poolToken,
        address wethToken,
        string memory liquidityTokenName,
        string memory liquidityTokenSymbol
    ) ERC20(liquidityTokenName, liquidityTokenSymbol) {
        i_wethToken = IERC20(wethToken);
        i_poolToken = IERC20(poolToken);
    }
 	```
 </details>

 ## [I-7] Use of `magic numbers` in TSwapPool::getOutputAmountBasedOnInput` should be avoided.

**Description**It can be cofuncing to see number literals in a codebase, and it's much more readable of the numbers are given in a code base.

```diff
+        uint256 constant VALUE_AFTER_FEE_DEDUCTION = 997;
+        uint256 constant VALUE_AFTER_FEE_MULTIPLICATION = 1000;    

-       uint256 inputAmountMinusFee = inputAmount * 997;
+       uint256 inputAmountMinusFee = inputAmount * VALUE_AFTER_FEE_DEDUCTION;
        uint256 numerator = inputAmountMinusFee * outputReserves;
-        uint256 denominator = (inputReserves * 1000) + inputAmountMinusFee;
+        uint256 denominator = (inputReserves * VALUE_AFTER_FEE_MULTIPLICATION) + inputAmountMinusFee;

```