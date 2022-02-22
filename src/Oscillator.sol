// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC721 } from "@solmate/tokens/ERC721.sol"; // Solmate: ERC721

/// @title Oscillator 
/// @notice ERC721 with LBP-like price discovery
/// @author Sam Sends <sam@glass.xyz>
/// @dev Solmate ERC721 includes unused _burn logic that can be removed to optimize deployment cost
contract Oscillator is ERC721 {

    /*///////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    // TODO: add any events (avoiding a mint event to keep gas down)

    /*///////////////////////////////////////////////////////////////
                          MUTABLE STORAGE                        
    //////////////////////////////////////////////////////////////*/
    
    /// @notice ERC721 base URI for tokenURI
    string public baseURI;

    /// @notice last time that an ERC721 was minted (or auction start)
    uint256 public time;

    /// @notice last price (or starting price)
    uint256 public price;

    /// @notice token index for token ID tracking
    uint256 public tokenIndex;


    /*///////////////////////////////////////////////////////////////
                          IMMUTABLE STORAGE                        
    //////////////////////////////////////////////////////////////*/

    /// @notice minimum price that an ERC721 can sell for
    uint256 immutable public minimumPrice;

    /// @notice the amount that price decays per block
    uint256 immutable public priceDecayPerBlock;

    /// @notice the amount that price increases after each mint
    uint256 immutable public priceIncreasePerMint;

    /// @notice the total number of tokens for sale
    uint256 immutable public numberOfTokens;

    /// @notice switch concatenate tokenId to baseURI
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

    /// @notice Thrown if the contract has sold out
    error SoldOut();

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new LBPERC721 contract
    /// @param _name of token
    /// @param _symbol of token
    /// @param _baseURI of token
    /// @param _startingTime of intial mint
    /// @param _startingPrice of initial mint
    /// @param _minimumPrice of the token
    /// @param _priceDecayPerBlock price decay over time
    /// @param _priceIncreasePerMint price increase per mint
    /// @param _numberOfTokens to be minted
    /// @param _concatenateTokenId to base URI
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _startingTime,
        uint256 _startingPrice,
        uint256 _minimumPrice,
        uint256 _priceDecayPerBlock,
        uint256 _priceIncreasePerMint,
        uint256 _numberOfTokens,
        bool _concatenateTokenId
    ) ERC721(_name, _symbol){
        time = _startingTime;
        price = _startingPrice;
        baseURI = _baseURI;
        minimumPrice = _minimumPrice;
        priceDecayPerBlock = _priceDecayPerBlock;
        priceIncreasePerMint = _priceIncreasePerMint;
        numberOfTokens = _numberOfTokens;
        concatenateTokenId = _concatenateTokenId;
    }

    /*///////////////////////////////////////////////////////////////
                              MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice allows minting a token at the given sale price
    function mint() external payable {

        // throw errors if minting has not started or sold out
        if (time > block.timestamp) revert MintingHasNotStarted();
        if (tokenIndex >= numberOfTokens) revert SoldOut();

        // calculate mint price
        uint256 mintPrice = price - ((block.timestamp - time) * priceDecayPerBlock);

        // if mint price is below minimum price, reset to minimum
        if (mintPrice < minimumPrice) {
            mintPrice = minimumPrice;
        }


        // if someone pays too little, revert
        if (msg.value < mintPrice) revert ValueBelowMintPrice();

        // if someone over pays, refund
        if (msg.value - mintPrice > 0) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }

        // mint ERC721 and update token/price/time state
        _safeMint(msg.sender, tokenIndex);
        tokenIndex++;
        price = mintPrice + priceIncreasePerMint;
        time = block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                           ERC721 OVERRIDES
    //////////////////////////////////////////////////////////////*/ 

    /// @notice returns the token URI for a tokenID that exists
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (ownerOf[id] == address(0)) revert NonexistentToken();
        return concatenateTokenId ? string(abi.encodePacked(baseURI, toString(id))) : baseURI;
    }

    // TODO: ADD CONTRACT URI


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
