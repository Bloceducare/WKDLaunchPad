// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {WKDCommit} from "../src/WKDCommit.sol";
// import "../utils/IBEP20.sol";
import "forge-std/Script.sol";

contract CommitDeployment is Script {
    WKDCommit wkdCommit;
    address admin = 0x4b41BB4F684a369cB9a48B212F6c0628a3b6d843;

    function setUp() public {}

    function run() public {
        vm.broadcast();
        wkdCommit = new WKDCommit(admin);
        vm.broadcast();
    }
}
