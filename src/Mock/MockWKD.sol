// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


contract MOCKWAKANDA is ERC20("WAKANDA", "WKD") {
    constructor()  {
         _mint(msg.sender, 100000000e9);
    }

    function get() public {
        _mint(msg.sender, 100_000e9);
    }

    //mint a lot of tokens to target
    function send(address _target) public {
        _mint(_target, 100_000_000e9);
    }

    function decimals() public view override returns (uint8) {
        return 9;
    }
}