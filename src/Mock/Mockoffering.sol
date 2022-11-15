pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MOCKOFF is ERC20("OFFERING", "OFF") {
    constructor() {
        _mint(msg.sender, 1000000e18);
    }

    function get() public {
        _mint(msg.sender, 1000000e18);
    }

    function mintAmount(address user, uint256 amount) public {
        _mint(user, amount);
    }
}
