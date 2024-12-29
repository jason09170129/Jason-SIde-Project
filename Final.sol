
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
    // 資產結構體
    struct Property {
        uint256 salePriceInEth; // 使用 Ether 單位
        bool isForSale;
    }

    // 資料結構
    mapping(uint256 => address) public propertyOwners; // 資產擁有者
    mapping(uint256 => bool) public propertyExists;   // 資產是否存在
    mapping(uint256 => Property) public properties;   // 資產詳細資料
    mapping(address => bool) public isManager;        // 管理者列表
    mapping(address => bytes32) public buyerProofs; // 買家的金鑰


    // 事件
    event PropertyRegistered(uint256 indexed propertyId, address indexed owner);
    event PropertyForSale(uint256 indexed propertyId, uint256 salePriceInEth);
    event BuyerPaid(uint256 indexed propertyId, uint256 amountInEth, address indexed buyer);
    event OwnershipTransferred(uint256 indexed propertyId, address indexed seller, address indexed buyer);
    event ManagerRemoved(address indexed manager);
    event BuyerProofGenerated(address indexed buyer, bytes32 proof); 


    // 權限修飾詞
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    // modifier onlyManager() {
    //     require(isManager[msg.sender], "Only a manager can perform this action.");
    //     _;
    // }
    modifier onlyManager(address managerAddress) {
        require(isManager[managerAddress], "Only a valid manager can perform this action.");
        _;
    }

    modifier onlyPropertyOwner(uint256 propertyId) {
        require(propertyOwners[propertyId] == msg.sender, "Only the property owner can perform this action.");
        _;
    }

    constructor() payable {
        owner = msg.sender;
    }

    // 資產登記
    // function registerProperty(uint256 propertyId) public {
    //     require(!propertyExists[propertyId], "Property already registered.");
    //     propertyExists[propertyId] = true;
    //     propertyOwners[propertyId] = msg.sender;
    //     emit PropertyRegistered(propertyId, msg.sender);
    // }
    // function registerProperty(uint256 propertyId) public onlyManager {
    //     require(!propertyExists[propertyId], "Property already registered.");
    //     propertyExists[propertyId] = true;
    //     propertyOwners[propertyId] = msg.sender;
    //     emit PropertyRegistered(propertyId, msg.sender);
    // }
// 資產登記，僅限管理者執行，並檢查是否是指定的管理者
    // function registerProperty(address managerAddress,uint256 propertyId) public onlyManager {
    //     require(isManager[managerAddress], "The provided address is not a valid manager.");
    //     require(!propertyExists[propertyId], "Property already registered.");
    //     propertyExists[propertyId] = true;
    //     propertyOwners[propertyId] = msg.sender;
    //     emit PropertyRegistered(propertyId, msg.sender);
    // }
    function registerProperty(address managerAddress, uint256 propertyId) public onlyManager(managerAddress) {
        require(!propertyExists[propertyId], "Property already registered.");
        propertyExists[propertyId] = true;
        propertyOwners[propertyId] = msg.sender; // 設定資產擁有者為執行交易者
        emit PropertyRegistered(propertyId, msg.sender);
    }


 
    // 管理者新增與移除
    function addManager(address manager) public  {
        isManager[manager] = true;
    }

    //批准買家
    // function proofBuyer(address managerAddress, address buyer) public onlyManager {
    //     require(isManager[managerAddress], "The provided address is not a valid manager.");
    //     bytes32 proof = keccak256(abi.encodePacked(managerAddress, buyer, block.timestamp));
    //     buyerProofs[buyer] = proof;
    //     emit BuyerProofGenerated(buyer, proof);
    // }
    function proofBuyer(address managerAddress, address buyer) public {
        require(isManager[managerAddress], "The provided address is not a valid manager."); // 驗證指定的管理者
        bytes32 proof = keccak256(abi.encodePacked(managerAddress, buyer, block.timestamp));
        buyerProofs[buyer] = proof; // 將 proof 儲存到映射中
        emit BuyerProofGenerated(buyer, proof); // 發出事件通知
    }

    function removeManager(address manager) public onlyOwner {
        require(isManager[manager], "Address is not a manager.");
        isManager[manager] = false;
        emit ManagerRemoved(manager);
    }

    // 設定房產為出售
    // function setPropertyForSale(uint256 propertyId, uint256 salePriceInEth) public onlyPropertyOwner(propertyId) {
    //     require(propertyExists[propertyId], "Property does not exist.");
    //     properties[propertyId] = Property({
    //         salePriceInEth: salePriceInEth,
    //         isForSale: true
    //     });
    //     emit PropertyForSale(propertyId, salePriceInEth);
    // }
    function setPropertyForSale(address managerAddress,uint256 propertyId, uint256 salePriceInEth) public onlyPropertyOwner(propertyId) {
        require(isManager[managerAddress], "The provided address is not a valid manager.");
        require(propertyExists[propertyId], "Property does not exist.");
        properties[propertyId] = Property({
            salePriceInEth: salePriceInEth,
            isForSale: true
        });
        emit PropertyForSale(propertyId, salePriceInEth);
    }

 
    // function buyProperty(uint256 propertyId, uint256 paymentAmountInEth) public payable {
    //     require(propertyExists[propertyId], "Property does not exist.");
    //     require(properties[propertyId].isForSale, "Property is not for sale.");
    //     require(paymentAmountInEth == properties[propertyId].salePriceInEth, "Incorrect payment amount.");

    //     address seller = propertyOwners[propertyId];
    //     propertyOwners[propertyId] = msg.sender;
    //     properties[propertyId].isForSale = false;

    //     // Transfer payment to the seller
    //     payable(seller).transfer(msg.value);

    //     emit BuyerPaid(propertyId, paymentAmountInEth, msg.sender);
    //     emit OwnershipTransferred(propertyId, seller, msg.sender);
    // }
    function buyProperty(bytes32 buyerProof,uint256 propertyId, uint256 paymentAmountInEth) public payable {
        require(propertyExists[propertyId], "Property does not exist.");
        require(properties[propertyId].isForSale, "Property is not for sale.");
        require(paymentAmountInEth == properties[propertyId].salePriceInEth, "Incorrect payment amount.");
        require(buyerProofs[msg.sender] == buyerProof, "Invalid buyer proof."); // 驗證金鑰

        address seller = propertyOwners[propertyId];
        propertyOwners[propertyId] = msg.sender;
        properties[propertyId].isForSale = false;

        // Transfer payment to the seller
        payable(seller).transfer(msg.value);

        emit BuyerPaid(propertyId, paymentAmountInEth, msg.sender);
        emit OwnershipTransferred(propertyId, seller, msg.sender);
    }

    // 查詢功能
    function getPropertyStatus(uint256 propertyId) public view returns (bool isForSale, uint256 salePriceInEth) {
        require(propertyExists[propertyId], "Property does not exist.");
        Property memory property = properties[propertyId];
        return (property.isForSale, property.salePriceInEth); // 返回 Ether 單位的價格
    }

    function getOwnerOfProperty(uint256 propertyId) public view returns (address) {
        require(propertyExists[propertyId], "Property does not exist.");
        return propertyOwners[propertyId];
    }
}

