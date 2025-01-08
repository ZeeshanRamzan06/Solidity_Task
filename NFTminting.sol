// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract NFTMinter {
    struct NFT {
        uint256 tokenId;
        string name;
        address collection;
        address owner;
        uint256 collectionId;
    }
    
    struct Collection {
        uint256 collectionId;
        string name;
        address creator;
        bool exists;
    }
    
    struct NFTDetails {
        uint256 tokenId;
        string name;
        address owner;
        uint256 collectionId;
        string collectionName;
    }
    
    mapping(string => uint256) private collectionNameToId;
    mapping(uint256 => NFT) public nfts;
    mapping(uint256 => Collection) public collections;
    mapping(address => uint256[]) private userNFTs;
    mapping(address => uint256[]) private creatorCollections;
    mapping(address => uint256[]) private collectionNFTs;
    mapping(uint256 => bool) private usedTokenIds;
    mapping(uint256 => bool) private usedCollectionIds;
    
    uint256 private tokenCounter;
    
    constructor() {
        tokenCounter = 1;
    }

    function generateRandomCollectionId(address sender) private view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    sender,
                    block.number
                )
            )
        );
        return (randomNumber % 1000000) + 1;
    }
    
    function generateRandomTokenId(address sender) private view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    sender,
                    tokenCounter
                )
            )
        );
        return randomNumber % 1000000;
    }
    
    function createCollection(string memory _name) public returns (uint256) {
        require(bytes(_name).length > 0, "Collection name cannot be empty");
        require(collectionNameToId[_name] == 0, "Collection name already exists");
        
        uint256 collectionId;
        bool unique = false;
        
        while (!unique) {
            collectionId = generateRandomCollectionId(msg.sender);
            if (!usedCollectionIds[collectionId]) {
                unique = true;
                usedCollectionIds[collectionId] = true;
            }
        }
        
        collections[collectionId] = Collection({
            collectionId: collectionId,
            name: _name,
            creator: msg.sender,
            exists: true
        });
        
        collectionNameToId[_name] = collectionId;
        creatorCollections[msg.sender].push(collectionId);
        return collectionId;
    }

    function getCollectionByName(string memory _name) public view returns (
        uint256 collectionId,
        string memory name,
        address creator,
        bool exists
    ) {
        uint256 id = collectionNameToId[_name];
        require(id != 0, "Collection not found");
        Collection memory collection = collections[id];
        return (
            collection.collectionId,
            collection.name,
            collection.creator,
            collection.exists
        );
    }

    function getCollectionById(uint256 _collectionId) public view returns (
        uint256 collectionId,
        string memory name,
        address creator,
        bool exists
    ) {
        require(collections[_collectionId].exists, "Collection not found");
        Collection memory collection = collections[_collectionId];
        return (
            collection.collectionId,
            collection.name,
            collection.creator,
            collection.exists
        );
    }

    function getNFTsByCollectionName(string memory _collectionName) public view returns (NFTDetails[] memory) {
        uint256 collectionId = collectionNameToId[_collectionName];
        require(collectionId != 0, "Collection not found");
        Collection memory collection = collections[collectionId];
        return getNFTsByCollection(collection.creator);
    }

    function mintNFT(uint256 _collectionId, string memory _name) public returns (uint256) {
        require(collections[_collectionId].exists, "Collection does not exist");
        require(bytes(_name).length > 0, "NFT name cannot be empty");
        
        uint256 newTokenId;
        bool unique = false;
        
        while (!unique) {
            newTokenId = generateRandomTokenId(msg.sender);
            if (!usedTokenIds[newTokenId]) {
                unique = true;
                usedTokenIds[newTokenId] = true;
            }
        }
        
        nfts[newTokenId] = NFT({
            tokenId: newTokenId,
            name: _name,
            collection: collections[_collectionId].creator,
            owner: msg.sender,
            collectionId: _collectionId
        });
        
        userNFTs[msg.sender].push(newTokenId);
        collectionNFTs[collections[_collectionId].creator].push(newTokenId);
        tokenCounter++;
        return newTokenId;
    }
    
    function getNFTsByOwner(address _owner) public view returns (NFTDetails[] memory) {
        uint256[] memory tokenIds = userNFTs[_owner];
        NFTDetails[] memory details = new NFTDetails[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            NFT memory nft = nfts[tokenIds[i]];
            Collection memory collection = collections[nft.collectionId];
            
            details[i] = NFTDetails({
                tokenId: nft.tokenId,
                name: nft.name,
                owner: nft.owner,
                collectionId: nft.collectionId,
                collectionName: collection.name
            });
        }
        
        return details;
    }
    
    function getNFTsByCollection(address _collection) public view returns (NFTDetails[] memory) {
        uint256[] memory tokenIds = collectionNFTs[_collection];
        NFTDetails[] memory details = new NFTDetails[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            NFT memory nft = nfts[tokenIds[i]];
            Collection memory collection = collections[nft.collectionId];
            
            details[i] = NFTDetails({
                tokenId: nft.tokenId,
                name: nft.name,
                owner: nft.owner,
                collectionId: nft.collectionId,
                collectionName: collection.name
            });
        }
        
        return details;
    }
}