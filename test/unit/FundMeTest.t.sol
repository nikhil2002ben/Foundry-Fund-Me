//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // Give USER 10 ETH
    }

    function testMinDollarIsFive() public view {
        assertEq(fundMe.MIN_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        //console.log(fundMe.i_owner());
        // console.log(msg.sender);
        // assertEq(fundMe.i_owner(), msg.sender);

        // We are deploying the fundMe contract through the fundMeTest contract, so the fundMeTest contract is the owner and not us

        // assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4); // Assuming the version is 4, change it if necessary
    }

    function testFundFailIfNotEnoughETH() public {
        vm.expectRevert();
        fundMe.fund(); //Sending 0 ETH should revert
        console.log("%s", "testFundFailIfNotEnoughETH passed");
    }

    function testIfFundDataUpdates() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArray() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Grab starting balances
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        //Withdraw funds
        vm.txGasPrice(GAS_PRICE); // Set gas price for the transaction
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Grab ending balances
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        // Assertion
        assertEq(endingOwnerBalance, startingOwnerBalance + startingContractBalance);
        assertEq(address(fundMe).balance, 0);
    }

    function testWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax is a combination vm.prank and vm.deal and it is a forge-std command so no need to use vm cheatcode.
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }
        //Grab starting balances
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        //Withdraw funds
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Grab ending balances
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(address(fundMe).balance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingContractBalance);
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax is a combination vm.prank and vm.deal and it is a forge-std command so no need to use vm cheatcode.
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }
        //Grab starting balances
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        //Withdraw funds
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        //Grab ending balances
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(address(fundMe).balance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingContractBalance);
    }
}
