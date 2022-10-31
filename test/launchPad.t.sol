// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/launchpad.sol";
import "../src/WKDCommit.sol";
import "../src/Mock/Mockoffering.sol";
import "../src/Mock/MockWKD.sol";

contract IFOTest is Test {
    Launchpad launchpad;
    WKDCommit wkdCommit;
    MOCKOFF mOFF;
    MOCKWAKANDA mWKD;

    address admin = mkaddr("Admin");
    address user1 = mkaddr("user1");
    address user2 = mkaddr("User2");
    address user3 = mkaddr("User3");
    function setUp() public {
        mOFF = new MOCKOFF();
        wkdCommit = new WKDCommit();
        mWKD = new MOCKWAKANDA();
        launchpad = new Launchpad();
        launchpad.initialize(address(mOFF),block.timestamp + 2 days, block.timestamp + 1 weeks, admin, address(wkdCommit));
        vm.startPrank(admin);
        mWKD.mintToUser();
        mWKD.approve(address(admin), 1000000e9);
        wkdCommit.initialize(address(mWKD));
        vm.stopPrank();
    }
function testAdmin() public{
     vm.startPrank(admin);
        mOFF.mintToUser(admin);
        mOFF.approve(address(launchpad), 1000000e18);
        launchpad.setPool(
            1000,10000,4,4,400
        );
        vm.stopPrank();
}


    function testUser1() public {
        

        vm.startPrank(user1);
        vm.roll(4 days);
        mWKD.approve(address(wkdCommit), 1000000e9);
        mWKD.mintToUser();
        
        wkdCommit.commitWkd(1000e9);
        wkdCommit.getUserCommit(user1);
        vm.deal(user1,100 ether);
        launchpad.deposit{value: 0.003 ether}();
        vm.stopPrank();

        vm.startPrank(user2);
        vm.roll(3 days);
        mWKD.approve(address(wkdCommit), 1000000e9);
        mWKD.mintToUser();
        
        wkdCommit.commitWkd(1000e9);
        wkdCommit.getUserCommit(user1);
        vm.deal(user2,100 ether);
        launchpad.deposit{value: 0.007 ether}();
        vm.stopPrank();

        // check for raised ampunt
        launchpad.raisedAmount();
        //  user claims offering tokens
        vm.startPrank(user1);
        vm.roll(3 weeks);
        launchpad.harvestPool();
        vm.stopPrank();
   
    }


    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }
}
//
