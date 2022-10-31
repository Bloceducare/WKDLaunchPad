// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MOCKWAKANDA is ERC20("WAKANDA", "WKD") {
    constructor() {
        _mint(msg.sender, 1000000e9);
    
    }
    function mintToUser() public {
        _mint(msg.sender, 1000000e9);
    }
}

