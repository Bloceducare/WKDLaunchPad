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
    address projectOwner = mkaddr("ProjectOwner");
    address user1 = mkaddr("user1");
    address user2 = mkaddr("User2");
    address user3 = mkaddr("User3");

    function setUp() public {
        mOFF = new MOCKOFF();
        wkdCommit = new WKDCommit(admin);
        mWKD = new MOCKWAKANDA();
        launchpad = new Launchpad(0.000003 ether,0.007 ether );
        launchpad.initialize(
            address(mOFF),
            block.timestamp + 2 days,
            block.timestamp + 1 weeks,
            admin,
            projectOwner,
            address(wkdCommit),
            9000000000,
            10000 ether,
            4,
            40,
            400


        );
        vm.startPrank(admin);
        // mWKD.get();
        mWKD.approve(address(admin), 1000000e9);
        wkdCommit.initialize(address(mWKD));
        vm.stopPrank();
        mOFF.balanceOf(address(launchpad));
        mOFF.mintAmount(address(launchpad), 9000000000);
        mOFF.balanceOf(address(launchpad));
    }

    function testAdmin() public {
        vm.startPrank(admin);
        mOFF.mintToUser(admin);
        mOFF.approve(address(launchpad), 1000000e18);
        // launchpad.sendOfferingToken(9000000000);

        vm.stopPrank();
    }

    function testUser1() public {
        launchpad.raisedAmount();
        vm.startPrank(user1);
        vm.roll(4 days);
        mWKD.approve(address(wkdCommit), 1000000e9);
        mWKD.get();

        wkdCommit.commitWkd(1000e9);
        wkdCommit.getUserCommit(user1);
        vm.deal(user1, 100 ether);
        launchpad.raisedAmount();
        launchpad.deposit{value: 0.000003 ether}();
        // launchpad.userDetails();
        launchpad.raisedAmount();
        launchpad.isInitialized();
        vm.stopPrank();

        vm.startPrank(user2);
        // vm.roll(3 days);
        mWKD.approve(address(wkdCommit), 1000000e9);
        mWKD.get();

        wkdCommit.commitWkd(1000e9);
        wkdCommit.getUserCommit(user1);
        vm.deal(user2, 100 ether);
        launchpad.deposit{value: 0.007 ether}();
        launchpad.raisedAmount();
        launchpad.getTier1Amount();
        launchpad.getTier2Amount();
        launchpad.getLaunchPadInfo();

        vm.stopPrank();
        launchpad.raisedAmount();
        // user claim offerng token
        vm.roll(2 weeks);
        // userDetails(user1);
        vm.startPrank(user1);
        launchpad.getOfferingTokenAmount(user1);
        launchpad.getUserDetails(user1);
        mOFF.balanceOf(address(this));
        launchpad.getTier2Amount();
        mOFF.balanceOf(address(this));
        launchpad.getTier1Amount();
        launchpad.claimToken();

        vm.stopPrank();
        vm.prank(user2);
        launchpad.claimToken();
        vm.prank(admin);
        launchpad.finalWithdraw();
    }

    function mkaddr(string memory name) public returns (address) {
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);
        return addr;
    }
}
//
