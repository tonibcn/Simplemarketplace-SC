// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract SimpleMarketplace {
    struct Item {
        uint id;
        address payable seller;
        string name;
        uint price;
        bool sold;
    }

    uint public itemCount;
    mapping(uint => Item) public items;

    event ItemListed(uint id, address seller, string name, uint price);
    event ItemSold(uint id, address buyer, uint price);

    function listItem(string memory name, uint price) external {
        itemCount++;
        items[itemCount] = Item(
            itemCount,
            payable(msg.sender),
            name,
            price,
            false
        );
        emit ItemListed(itemCount, msg.sender, name, price);
    }

    function buyItem(uint id) external payable {
        Item storage item = items[id];
        require(id > 0 && id <= itemCount, "Invalid item ID");
        require(!item.sold, "Item already sold");
        require(msg.value == item.price, "Incorrect price");
        
        item.sold = true;
        (bool success, ) = item.seller.call{value: msg.value}("");
        require(success, "Transfer failed");
        
        emit ItemSold(id, msg.sender, msg.value);
    }

    function getItem(uint id) external view returns (Item memory) {
        return items[id];
    }
}
