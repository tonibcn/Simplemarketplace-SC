// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SimpleMarketplace} from "../src/SimpleMarketplace.sol";

contract SimpleMarketplaceTest is Test {
    SimpleMarketplace simpleMarketplace;
    address seller = address(1);
    address buyer = address(2);

    string itemName = "ExampleItem";
    uint256 price = 1 ether;

    function setUp() external {
        simpleMarketplace = new SimpleMarketplace();
    }

    function test_ListItem() external {
        vm.expectEmit(true, true, true, true);
        emit SimpleMarketplace.ItemListed(1, seller, itemName, price);

        vm.prank(seller);
        simpleMarketplace.listItem(itemName, price);

        SimpleMarketplace.Item memory item = simpleMarketplace.getItem(1);
        assertEq(item.id, 1);
        assertEq(item.seller, seller);
        assertEq(item.name, itemName);
        assertEq(item.price, price);
        assertFalse(item.sold);
    }

    function test_BuyItem() external {
        vm.prank(seller);
        simpleMarketplace.listItem(itemName, price);

        vm.deal(buyer, price);
        vm.prank(buyer);
        vm.expectEmit(true, true, true, true);
        emit SimpleMarketplace.ItemSold(1, buyer, price);

        simpleMarketplace.buyItem{value: price}(1);

        SimpleMarketplace.Item memory item = simpleMarketplace.getItem(1);
        assertTrue(item.sold);

        uint256 sellerBalance = seller.balance;
        assertEq(sellerBalance, price);
    }

    function test_BuyItem_RevertWhen_InvalidItemId() external {
        vm.expectRevert("Invalid item ID");
        simpleMarketplace.buyItem{value: price}(1);
    }

    function test_BuyItem_RevertWhen_ItemAlreadySold() external {
        vm.prank(seller);
        simpleMarketplace.listItem(itemName, price);

        hoax(buyer, price);
        simpleMarketplace.buyItem{value: price}(1);

        hoax(buyer, price);
        vm.expectRevert("Item already sold");
        simpleMarketplace.buyItem{value: price}(1);
    }

    function test_BuyItem_RevertWhen_IncorrectPrice() external {
        vm.prank(seller);
        simpleMarketplace.listItem(itemName, price);

        vm.prank(buyer);
        vm.expectRevert("Incorrect price");
        simpleMarketplace.buyItem(1);
    }

    function test_BuyItem_RevertWhen_TransferFailed() external {
        FakeContract fakeContract = new FakeContract();
        vm.prank(address(fakeContract));
        simpleMarketplace.listItem(itemName, price);

        hoax(buyer, price);
        vm.expectRevert("Transfer failed");
        simpleMarketplace.buyItem{value: price}(1);
    }
}

contract FakeContract {}
