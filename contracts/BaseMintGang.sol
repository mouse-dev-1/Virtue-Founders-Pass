// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/*
BaseMintGang.sol
written by: mousedev.eth
*/

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "./MerkleWhitelist.sol";

contract BaseMintGang is ERC721A, MerkleWhitelist {
    uint256 maxSupply = 6900;
    uint256 supplyForSale = 6400;
    uint256 mintPrice = 0.1 ether;

    string public contractURI;
    string public unrevealedURI;
    string public baseURI;

    bool public revealed;

    uint256 internal shiftAmount;
    uint256 internal commitBlock;

    uint256 whitelistStartTime;
    bool whitelistActive;

    uint256 publicStartTime;
    bool publicActive;

    struct TokenStakeDetails{
        uint128 currentStakeTimestamp;
        uint128 totalStakeTimeAccrued;
    }

    mapping(uint256 => TokenStakeDetails) public tokenStakeDetails;


    constructor() ERC721A("BaseMint Gang", "BMG") {}

    /*
        user funcs
    */

    function stake(uint256[] memory _tokenIds) public {
        for(uint256 i =0;i<_tokenIds.length;i++){
            uint256 _tokenId = _tokenIds[i];

            TokenStakeDetails memory _tokenStakeDetails = tokenStakeDetails[_tokenId];

            require(msg.sender == ownerOf(_tokenId), "You do not own this token!");
            require(_tokenStakeDetails.currentStakeTimestamp == 0, "This token is already staked!");

            tokenStakeDetails[_tokenId] = TokenStakeDetails(
                uint128(block.timestamp),
                _tokenStakeDetails.totalStakeTimeAccrued
            );
        }
    }

    function unstake(uint256[] memory _tokenIds) public {
        for(uint256 i =0;i<_tokenIds.length;i++){
            uint256 _tokenId = _tokenIds[i];

            TokenStakeDetails memory _tokenStakeDetails = tokenStakeDetails[_tokenId];

            require(msg.sender == ownerOf(_tokenId), "You do not own this token!");
            require(_tokenStakeDetails.currentStakeTimestamp > 0, "This token is not staked!");

            uint128 secondsAccrued = uint128(block.timestamp) - _tokenStakeDetails.currentStakeTimestamp;
            uint128 totalSecondsAccrued = _tokenStakeDetails.totalStakeTimeAccrued + secondsAccrued;

            tokenStakeDetails[_tokenId] = TokenStakeDetails(
                0,
                totalSecondsAccrued
            );
        }
    }

    /*
  _____ _   _ _______ ______ _____  _   _          _        ______ _    _ _   _  _____ _______ _____ ____  _   _  _____ 
 |_   _| \ | |__   __|  ____|  __ \| \ | |   /\   | |      |  ____| |  | | \ | |/ ____|__   __|_   _/ __ \| \ | |/ ____|
   | | |  \| |  | |  | |__  | |__) |  \| |  /  \  | |      | |__  | |  | |  \| | |       | |    | || |  | |  \| | (___  
   | | | . ` |  | |  |  __| |  _  /| . ` | / /\ \ | |      |  __| | |  | | . ` | |       | |    | || |  | | . ` |\___ \ 
  _| |_| |\  |  | |  | |____| | \ \| |\  |/ ____ \| |____  | |    | |__| | |\  | |____   | |   _| || |__| | |\  |____) |
 |_____|_| \_|  |_|  |______|_|  \_\_| \_/_/    \_\______| |_|     \____/|_| \_|\_____|  |_|  |_____\____/|_| \_|_____/ 
 */


    function _getAuxIndex(uint8 _index) internal view returns (uint8) {
        return uint8(_getAux(msg.sender) >> (_index * 8));
    }

    function _setAuxIndex(uint8 _index, uint16 _num) internal {
        //Thx to @nftdoyler for helping me with bit shifting.
        uint256 bitMask = (2**(8 * (_index + 1)) - (2**(8 * _index)));
        _setAux(
            msg.sender,
            uint64(
                (_getAux(msg.sender) & ~bitMask) |
                    ((_num * (2**(8 * _index))) & bitMask)
            )
        );
    }

    function _beforeTokenTransfers(
        address from,
        address,
        uint256,
        uint256 _startingTokenId
    ) internal virtual override{
        //This means its being minted.
        if(from == address(0)) return;

        require(
            tokenStakeDetails[_startingTokenId].currentStakeTimestamp == 0,
            "Token Not Currently Transferrable"
        );
    }


    /*
 _  _  __  __ _  ____    ____  _  _  __ _   ___  ____  __  __   __ _  ____ 
( \/ )(  )(  ( \(_  _)  (  __)/ )( \(  ( \ / __)(_  _)(  )/  \ (  ( \/ ___)
/ \/ \ )( /    /  )(     ) _) ) \/ (/    /( (__   )(   )((  O )/    /\___ \
\_)(_/(__)\_)__) (__)   (__)  \____/\_)__) \___) (__) (__)\__/ \_)__)(____/
*/

    function mintWhitelist(uint8 _quantity, bytes32[] memory _proof)
        public
        payable
        onlyWhitelisted(_proof)
    {
        //Require supply isn't over minted.
        require(
            totalSupply() + _quantity <= supplyForSale,
            "Max supply reached!"
        );
        //Require they aren't minting too many.
        require(_quantity > 0 && _quantity < 3, "Can only mint up to 2!");
        //Require they send enough ether.
        require(msg.value >= _quantity * mintPrice, "Must send enough ether!");
        //Require whitelist sale is live
        require(
            block.timestamp >= whitelistStartTime && whitelistActive,
            "Whitelist sale isn't active!"
        );
        //Require this quantity doesn't take them over their alloc.
        require(
            _getAuxIndex(0) + _quantity <= 2,
            "You've minted your allocation!"
        );

        //Store they minted this many.
        _setAuxIndex(0, _getAuxIndex(0) + _quantity);

        //Mint them their tokens.
        _mint(msg.sender, _quantity);
    }

    function mintPublic(uint8 _quantity) public payable {
        //Require supply isn't over minted.
        require(
            totalSupply() + _quantity <= supplyForSale,
            "Max supply reached!"
        );
        //Require they aren't minting too many.
        require(_quantity > 0 && _quantity < 3, "Can only mint up to 2!");
        //Require they send enough ether.
        require(msg.value >= _quantity * mintPrice, "Must send enough ether!");
        //Require public sale is live.
        require(
            block.timestamp >= publicStartTime && publicActive,
            "Public sale isn't active!"
        );
        //Require this quantity doesn't take them over their alloc.
        require(
            _getAuxIndex(1) + _quantity <= 2,
            "You've minted your allocation in public!"
        );

        //Store they minted this many.
        _setAuxIndex(1, _getAuxIndex(1) + _quantity);

        //Mint them their tokens.
        _mint(msg.sender, _quantity);
    }

    /*
   U  ___ u              _   _   U _____ u   ____          _____    _   _   _   _      ____   _____             U  ___ u  _   _    ____     
    \/"_ \/__        __ | \ |"|  \| ___"|/U |  _"\ u      |" ___|U |"|u| | | \ |"|  U /"___| |_ " _|     ___     \/"_ \/ | \ |"|  / __"| u  
    | | | |\"\      /"/<|  \| |>  |  _|"   \| |_) |/     U| |_  u \| |\| |<|  \| |> \| | u     | |      |_"_|    | | | |<|  \| |><\___ \/   
.-,_| |_| |/\ \ /\ / /\U| |\  |u  | |___    |  _ <       \|  _|/   | |_| |U| |\  |u  | |/__   /| |\      | | .-,_| |_| |U| |\  |u u___) |   
 \_)-\___/U  \ V  V /  U|_| \_|   |_____|   |_| \_\       |_|     <<\___/  |_| \_|    \____| u |_|U    U/| |\u\_)-\___/  |_| \_|  |____/>>  
      \\  .-,_\ /\ /_,-.||   \\,-.<<   >>   //   \\_      )(\\,- (__) )(   ||   \\,-._// \\  _// \\_.-,_|___|_,-.  \\    ||   \\,-.)(  (__) 
     (__)  \_)-'  '-(_/ (_")  (_/(__) (__) (__)  (__)    (__)(_/     (__)  (_")  (_/(__)(__)(__) (__)\_)-' '-(_/  (__)   (_")  (_/(__)      
*/


    function airdropForVirtuePassHolders(address[] memory _addresses)
        public
        onlyOwner
    {
        require(
            totalSupply() + _addresses.length <= maxSupply,
            "Cannot exceed max supply."
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }


    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setRevealData(string memory _unrevealedURI) public onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    function commit(string memory _baseURI) public onlyOwner {
        require(
            (commitBlock == 0 || block.number >= commitBlock + 260) &&
                !revealed,
            "Only allow edits if not commited yet or commit expired"
        );

        commitBlock = block.number + 5;
        baseURI = _baseURI;
    }

    function reveal() public onlyOwner {
        require(block.number < commitBlock + 255, "Commit block expired!");

        shiftAmount = uint256(blockhash(commitBlock));
        revealed = true;
    }

    function setURIs(string memory _contractURI, string memory _baseURI)
        public
        onlyOwner
    {
        contractURI = _contractURI;
        baseURI = _baseURI;
    }
    
    function withdrawFunds() public onlyOwner {
        uint256 funds = address(this).balance;

        (bool succ, ) = payable(msg.sender).call{value: funds}("");
        require(succ, "transfer failed");
    }

    /*
  _____  ______          _____    ______ _    _ _   _  _____ _______ _____ ____  _   _  _____ 
 |  __ \|  ____|   /\   |  __ \  |  ____| |  | | \ | |/ ____|__   __|_   _/ __ \| \ | |/ ____|
 | |__) | |__     /  \  | |  | | | |__  | |  | |  \| | |       | |    | || |  | |  \| | (___  
 |  _  /|  __|   / /\ \ | |  | | |  __| | |  | | . ` | |       | |    | || |  | | . ` |\___ \ 
 | | \ \| |____ / ____ \| |__| | | |    | |__| | |\  | |____   | |   _| || |__| | |\  |____) |
 |_|  \_\______/_/    \_\_____/  |_|     \____/|_| \_|\_____|  |_|  |_____\____/|_| \_|_____/ 
*/



    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (revealed) {
            uint256 _newTokenId = (_tokenId + shiftAmount) % totalSupply();
            return
                string(
                    abi.encodePacked(baseURI, Strings.toString(_newTokenId))
                );
        } else {
            return unrevealedURI;
        }
    }

    function getAggregateTimeStaked(uint256 _tokenId) public view returns(uint128) {
        uint128 _totalStakeTimeAccrued = tokenStakeDetails[_tokenId].totalStakeTimeAccrued;
        uint128 _currentStakeTimestamp = tokenStakeDetails[_tokenId].currentStakeTimestamp;

        if(_currentStakeTimestamp == 0) return _totalStakeTimeAccrued;

        return _totalStakeTimeAccrued + (uint128(block.timestamp) - _currentStakeTimestamp);

    }

    function isStaked(uint256 _tokenId) public view returns(bool){
       return tokenStakeDetails[_tokenId].currentStakeTimestamp == 0 ? false : true;
    }
}
