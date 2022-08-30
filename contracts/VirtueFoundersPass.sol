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
    string public passURI = "ipfs://QmWyj1ufdbRkwgy1MiphN1ogA6Zh41EG68gUj8KDq5xUyA";
    string public contractURI = "ipfs://QmTbVy4g7rRwRSXLQpwQgbCMefr68GTKXCWquqnpAheZBo";

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

    function setURIs(string memory _contractURI, string memory _passURI) public onlyOwner{
        contractURI = _contractURI;
        passURI = _passURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist!");
        return passURI;
    }
}
