// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC721 } from "@solmate/tokens/ERC721.sol"; // Solmate: ERC721

contract LBPERC721 is ERC721 {

    /*///////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    // TODO: add any events (avoiding a mint event to keep gas down)

    /*///////////////////////////////////////////////////////////////
                          MUTABLE STORAGE                        
    //////////////////////////////////////////////////////////////*/
    
    string public baseURI;
    uint256 public time;
    uint256 public price;
    uint256 public tokenIndex;


    /*///////////////////////////////////////////////////////////////
                          IMMUTABLE STORAGE                        
    //////////////////////////////////////////////////////////////*/

    uint256 immutable public minimumPrice;
    uint256 immutable public priceDecayPerBlock;
    uint256 immutable public priceIncreasePerMint;
    uint256 immutable public numberOfEditions;
    bool immutable public concatenateTokenId;
    
    /*///////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown if address has already been registered for minting
    error AlreadyRegistered();

    /// @notice Thrown if someone tries to mint an NFT before the auction start
    error MintingHasNotStarted();

    /// @notice Thrown if someone pays less than the buy price for a mint
    error ValueBelowMintPrice();

    /// @notice Thrown if requesting tokenURI for nonexistent token
    error NonexistentToken();

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _startingTime,
        uint256 _startingPrice,
        uint256 _minimumPrice,
        uint256 _priceDecayPerBlock,
        uint256 _priceIncreasePerMint,
        uint256 _numberOfEditions,
        bool _concatenateTokenId
    ) ERC721(_name, _symbol){
        time = _startingTime;
        price = _startingPrice;
        baseURI = _baseURI;
        minimumPrice = _minimumPrice;
        priceDecayPerBlock = _priceDecayPerBlock;
        priceIncreasePerMint = _priceIncreasePerMint;
        numberOfEditions = _numberOfEditions;
        concatenateTokenId = _concatenateTokenId;
    }

    /*///////////////////////////////////////////////////////////////
                              MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function mint() external payable {

        if (time > block.timestamp) revert MintingHasNotStarted();

        uint256 mintPrice = price - ((block.timestamp - time) * priceDecayPerBlock);

        if (mintPrice < minimumPrice) {
            mintPrice = minimumPrice;
        }

        if (msg.value < mintPrice) revert ValueBelowMintPrice();

        if (msg.value - mintPrice > 0) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }

        _safeMint(msg.sender, tokenIndex);
        tokenIndex++;
        price = mintPrice + priceIncreasePerMint;
        time = block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                           ERC721 OVERRIDES
    //////////////////////////////////////////////////////////////*/ 

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (ownerOf[id] == address(0)) revert NonexistentToken();
        return concatenateTokenId ? string(abi.encodePacked(baseURI, toString(id))) : baseURI;
    }


    /*///////////////////////////////////////////////////////////////
                          UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/ 

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        // pulled from OZ strings util to keep gas down
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}
