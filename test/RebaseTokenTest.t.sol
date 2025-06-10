// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Test, console} from "forge-std/Test.sol";

import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";

import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    RebaseToken public rebaseToken;
    Vault public vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantMintAndBurnRole(address(vault));
        (bool success,) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();
    }

    // Helper function to send ETH to the vault
    function addRewardsToVault(uint256 rewardAmount) internal {
        (bool success,) = payable(address(vault)).call{value: rewardAmount}("");
        // For test setup, we might omit the success check, assuming it works.
        // In production tests, asserting success might be desired.
    }

    function testDepositLinear(uint256 amount) public {
        // Use bound instead of assume to keep more runs
        amount = bound(amount, 1e5, type(uint96).max);

        // 1. Deposit
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        // 2. Check initial balance
        uint256 startBalance = rebaseToken.balanceOf(user);
        assertEq(startBalance, amount);

        // 3. Warp time, check balance increases
        vm.warp(block.timestamp + 1 hours);
        uint256 middleBalance = rebaseToken.balanceOf(user);
        assertGt(middleBalance, startBalance);

        // 4. Warp time again, check balance increases
        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = rebaseToken.balanceOf(user);
        assertGt(endBalance, middleBalance);

        // 5. Check linearity with tolerance for truncation
        // Initial attempt: assertEq(endBalance - middleBalance, middleBalance - startBalance); // Fails due to truncation
        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1); // Correct approach
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);

        // 1. Deposit
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        assertEq(rebaseToken.balanceOf(user), amount);

        // 2. Redeem
        uint256 startEthBalance = address(user).balance;
        vm.prank(user); // Still acting as user
        vault.redeem(type(uint256).max); // Redeem entire balance

        // 3. Check balances
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, startEthBalance + amount);
    }

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) public {
        // Bound inputs
        depositAmount = bound(depositAmount, 1e5, type(uint96).max); // Use uint256 for amount
        time = bound(time, 1000, type(uint96).max / 1e18); // Bound time to avoid overflow in interest calc

        // 1. Deposit
        vm.deal(user, depositAmount);
        vm.prank(user);
        vault.deposit{value: depositAmount}();

        // 2. Warp time
        vm.warp(block.timestamp + time);
        uint256 balanceAfterSomeTime = rebaseToken.balanceOf(user);

        // 3. Fund vault with rewards
        console.log("Balance after some time: ", balanceAfterSomeTime);
        console.log("Deposit amount: ", depositAmount);
        uint256 rewardAmount = balanceAfterSomeTime - depositAmount;
        vm.deal(owner, rewardAmount); // Give owner ETH first
        vm.prank(owner);
        addRewardsToVault(rewardAmount); // Owner sends rewards

        // 4. Redeem
        uint256 ethBalanceBeforeRedeem = address(user).balance;
        vm.prank(user);
        vault.redeem(type(uint256).max);

        // 5. Check balances
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, ethBalanceBeforeRedeem + balanceAfterSomeTime);
        assertGt(address(user).balance, ethBalanceBeforeRedeem + depositAmount); // Ensure interest was received
    }

    function testTransfer(uint256 amount, uint256 amountToSend) public {
        // Bound inputs, ensure amount > amountToSend
        amount = bound(amount, 2e5, type(uint96).max); // Ensure enough to send
        amountToSend = bound(amountToSend, 1e5, amount - 1e5); // Ensure sender keeps some

        // 1. Deposit with initial rate (e.g., 5e10 assumed default)
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        address user2 = makeAddr("user2");
        uint256 userBalanceBefore = rebaseToken.balanceOf(user);
        uint256 user2BalanceBefore = rebaseToken.balanceOf(user2);
        assertEq(userBalanceBefore, amount);
        assertEq(user2BalanceBefore, 0);

        // 2. Owner lowers the global interest rate
        uint256 originalRate = rebaseToken.getUserInterestRate(user); // Assume 5e10
        uint256 newRate = originalRate / 2; // Example: 4e10 or similar lower rate
        vm.prank(owner);
        rebaseToken.setInterestRate(newRate);

        // 3. Transfer tokens
        vm.prank(user);
        rebaseToken.transfer(user2, amountToSend);

        // 4. Check final balances
        assertEq(rebaseToken.balanceOf(user), userBalanceBefore - amountToSend);
        assertEq(rebaseToken.balanceOf(user2), amountToSend);

        // 5. Check interest rate inheritance
        assertEq(rebaseToken.getUserInterestRate(user), originalRate); // User keeps original rate
        assertEq(rebaseToken.getUserInterestRate(user2), originalRate); // User2 inherits sender's original rate
    }

    function testCannotSetInterestRate(uint256 newInterestRate) public {
        vm.prank(user); // Impersonate unauthorized user
        // Expect revert with Ownable's specific error selector
        vm.expectPartialRevert(bytes4(Ownable.OwnableUnauthorizedAccount.selector));
        rebaseToken.setInterestRate(newInterestRate);
    }

    function testCannotCallMintAndBurn() public {
        vm.prank(user); // Impersonate unauthorized user

        // Test mint
        // Expect revert with AccessControl's specific error selector
        vm.expectPartialRevert(bytes4(IAccessControl.AccessControlUnauthorizedAccount.selector));
        rebaseToken.mint(user, 100, rebaseToken.getInterestRate());

        // Test burn (requires separate expectRevert)
        vm.prank(user); // Re-prank if needed, though context might persist
        vm.expectPartialRevert(bytes4(IAccessControl.AccessControlUnauthorizedAccount.selector));
        rebaseToken.burn(user, 100);
    }

    function testGetPrincipalBalance(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);

        // 1. Deposit
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        // 2. Check principal balance
        // Assuming function is named principleBalanceOf or similar
        assertEq(rebaseToken.principleBalanceOf(user), amount);

        // 3. Warp time
        vm.warp(block.timestamp + 1 hours);

        // 4. Check principal balance again - should be unchanged
        assertEq(rebaseToken.principleBalanceOf(user), amount);
    }
}
