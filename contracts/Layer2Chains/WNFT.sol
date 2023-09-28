// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

abstract contract WNFT is ERC721Burnable, CCIPReceiver {
    address immutable i_link;
    uint64 currentSelector;
    uint64 targetSelector;
    uint256 counter;

    struct WrappedToken {
        address contAddr;
        uint256 tokenId;
        string name;
        string symbol;
        string uri;
    }
    mapping(uint256 => WrappedToken) wrappedTokens;

    constructor(
        address router,
        address link
    ) ERC721("Wrapped NFT", "WNFT") CCIPReceiver(router) {
        i_link = link;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return (wrappedTokens[tokenId].uri);
    }

    function tokenInfo(uint256 wTokenId) public view returns(
        address contAddr,
        uint256 tokenId,
        string memory name,
        string memory symbol,
        string memory uri
    ) {
        WrappedToken memory wToken = wrappedTokens[wTokenId];
        contAddr = wToken.contAddr;
        tokenId = wToken.tokenId;
        name = wToken.name;
        symbol = wToken.symbol;
        uri = wToken.uri;
    }

    function wMint(
        address userAddr,
        address contAddr,
        uint256 tokenId,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) internal {
        uint256 wTokenId = ++counter;
        wrappedTokens[wTokenId] = WrappedToken(
            contAddr,
            tokenId,
            _name,
            _symbol,
            _uri
        );

        _safeMint(userAddr, wTokenId);
    }

    function _getFee(
        address contAddr,
        address userAddr,
        uint256 tokenId,
        bool payInLink
    ) internal view returns (uint256 fee) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(
                contAddr,
                userAddr,
                tokenId
            ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payInLink ? i_link : address(0)
        });

        // Get the fee required to send the message
        fee = IRouterClient(i_router).getFee(targetSelector, message);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(CCIPReceiver, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}