// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


/*

VirtueFoundersPass.sol

written by: mousedev.eth

*/
// Import this file to use console.log
import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "./MerkleWhitelist.sol";

contract VirtueFoundersPass  is ERC721A, MerkleWhitelist{
    string public baseURI;
    string public collectionURI;

    uint256 maxSupply = 500;
    constructor() ERC721A("Virtue Founders Pass", "VFP") {}

    function mintWhitelist(bytes32[] memory proof) public onlyWhitelisted(proof){
        require(_numberMinted(msg.sender) == 0, "You already minted!");
        require(totalSupply() + 1 <= maxSupply, "Max supply reached!");
        _mint(msg.sender, 1);
    }

    function mintAdmin(uint256 _quantity) public onlyOwner{
        require(totalSupply() + _quantity <= maxSupply, "Max supply reached!");
        _mint(msg.sender, _quantity);
    }

    function setURIs(string memory _collectionURI, string memory _baseURI) public onlyOwner{
        collectionURI = _collectionURI;
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
}
