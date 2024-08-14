//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("Mock", "MCK"){}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}