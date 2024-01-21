// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {HeritageContract} from "../src/Heritage.sol";

contract HeritageTest is Test {
    ///////////////
    //// SETUP ////
    ///////////////
    HeritageContract public heritage;

    error ClaimTimeMustGreaterThanCurrentTime();
    error RecipientMustBeDifferentFromSender();
    error ValueMustGreaterThanZero();
    error TransactionFailed();
    error NotRecipient();
    error NotSender();
    error HeritageHasBeenClaimed();
    error ClaimTimeNotFulfilled();

    function setUp() public {
        heritage = new HeritageContract();
    }

    receive() external payable {}

    fallback() external payable {}

    //////////////////////////
    //// CONSTURCTOR TEST ////
    //////////////////////////
    function test_heritageConstructor() public {
        uint256 heritageId = 1;
        assertEq(heritage.getHeritageId(), heritageId);
    }

    ///////////////////////
    //// FUNCTION TEST ////
    ///////////////////////
    function test_createHeritage() public {
        uint256 claimTime = 1705712121;
        address recipient = address(1);

        heritage.createHeritage{value: 1 ether}(claimTime, recipient);

        (
            uint256 _value,
            uint256 _claimTime,
            address _sender,
            address _recipient,
            bool _status
        ) = heritage.heritages(1);

        assertEq(_value, 1 ether);
        assertEq(_claimTime, claimTime);
        assertEq(_sender, address(this));
        assertEq(_recipient, recipient);
        assertEq(_status, false);
        assertEq(heritage.getHeritageId(), 2);
    }

    function test_changeHeritage() public {
        // Create Heritage
        uint256 claimTime1 = 1705712121;
        address recipient1 = address(1);
        heritage.createHeritage{value: 1 ether}(claimTime1, recipient1);

        uint256 claimTime2 = 1706000000;
        address recipient2 = address(2);
        heritage.createHeritage{value: 2 ether}(claimTime2, recipient2);

        (, , , address _recipient1, ) = heritage.heritages(1);
        (, , , address _recipient2, ) = heritage.heritages(2);
        assertEq(_recipient1, recipient1);
        assertEq(_recipient2, recipient2);

        // Change Heritage
        address newRecipient1 = address(12);
        heritage.changeHeritage{value: 2 ether}(1, claimTime1, newRecipient1);

        uint256 newClaimTime2 = 1707000000;
        heritage.changeHeritage{value: 5 ether}(2, newClaimTime2, recipient2);

        (uint256 _value1, , , address _getNewRecipient1, ) = heritage.heritages(
            1
        );
        (uint256 _value2, uint256 _newClaimTime2, , , ) = heritage.heritages(2);

        assertEq(_value1, 2 ether);
        assertEq(_getNewRecipient1, newRecipient1);
        assertEq(_value2, 5 ether);
        assertEq(_newClaimTime2, newClaimTime2);
    }

    function test_claimHeritage() public {
        // Create Heritage
        uint256 claimTime = 1706000000;
        address recipient = address(10);
        heritage.createHeritage{value: 10 ether}(claimTime, recipient);

        // Claim Heritage
        uint256 blockStartAt = 1706100000;
        uint256 recipientBalanceBefore = recipient.balance;

        vm.warp(blockStartAt);
        vm.startPrank(recipient);
        heritage.claimHeritage(1);
        vm.stopPrank();

        uint256 recipeintBalanceAfter = recipient.balance;

        // Testing
        (, , , , bool _status) = heritage.heritages(1);

        assert(recipientBalanceBefore < recipeintBalanceAfter);
        assertEq(_status, true);
    }

    function test_getHeritageId() public {
        uint256 claimTime1 = 1706000000;
        address recipient1 = address(10);
        heritage.createHeritage{value: 10 ether}(claimTime1, recipient1);

        uint256 claimTime2 = 1706100000;
        address recipient2 = address(11);
        heritage.createHeritage{value: 4 ether}(claimTime2, recipient2);

        uint256 claimTime3 = 1708000000;
        address recipient3 = address(5);
        heritage.createHeritage{value: 32 ether}(claimTime3, recipient3);

        assertEq(heritage.getHeritageId(), 4);
    }

    ////////////////////
    //// ERROR TEST ////
    ////////////////////

    //// CREATE HERITAGE FUNCTION ////
    function test_errorClaimTimeMustGreaterThanCurrentTime() public {
        uint256 claimTime = 1000000;
        uint256 currentTime = 1706100000;
        vm.warp(currentTime);
        vm.expectRevert(
            HeritageContract.ClaimTimeMustGreaterThanCurrentTime.selector
        );
        heritage.createHeritage{value: 1 ether}(claimTime, address(1));
    }

    function test_errorValueMustGreaterThanZero() public {
        vm.expectRevert(HeritageContract.ValueMustGreaterThanZero.selector);
        heritage.createHeritage{value: 0 ether}(1706100000, address(1));
    }

    function test_errorRecipientMustBeDifferentFromSender() public {
        vm.expectRevert(
            HeritageContract.RecipientMustBeDifferentFromSender.selector
        );
        heritage.createHeritage{value: 1 ether}(1706100000, address(this));
    }

    //// CHANGE HERITAGE FUNCTION ////
    function test_errorHeritageHasBeenClaimed() public {
        heritage.createHeritage{value: 1 ether}(1706100000, address(4));
        vm.warp(1706200000);
        vm.startPrank(address(4));
        heritage.claimHeritage(1);
        vm.stopPrank();

        vm.expectRevert(HeritageContract.HeritageHasBeenClaimed.selector);
        heritage.changeHeritage{value: 2 ether}(1, 1707100000, address(3));
    }

    function test_errorNotSender() public {
        heritage.createHeritage{value: 1 ether}(1706100000, address(4));

        vm.deal(address(10), 10 ether);
        vm.prank(address(10));
        vm.expectRevert(HeritageContract.NotSender.selector);
        heritage.changeHeritage{value: 2 ether}(1, 1707100000, address(9));
    }

    //// CLAIM HERITAGE FUNCTION ////
    function test_errorNotRecipient() public {
        heritage.createHeritage{value: 1 ether}(1706100000, address(1));
        vm.expectRevert(HeritageContract.NotRecipient.selector);
        heritage.claimHeritage(1);
    }

    function test_errorClaimTimeNotFulfilled() public {
        heritage.createHeritage{value: 1 ether}(1706100000, address(1));
        vm.prank(address(1));
        vm.expectRevert(HeritageContract.ClaimTimeNotFulfilled.selector);
        heritage.claimHeritage(1);
    }
}
