// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "./utils/Swapper.sol";
import "./utils/Burner.sol";

contract Ethereum_Cross_NFT is Swapper, Burner, ERC721Burnable, CCIPReceiver {
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
        uint64 _currentSelector,
        uint64 _targetSelector,
        address router,
        address link
    ) ERC721("Ethereum_Wrapped_NFT", "wNFT") CCIPReceiver(router) {
        i_link = link;
        currentSelector = _currentSelector;
        targetSelector = _targetSelector;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);
    }

    function tokenURI(
        uint256 wTokenId
    ) public view override returns (string memory) {
        _requireMinted(wTokenId);
        return (wrappedTokens[wTokenId].uri);
    }

    function tokenInfo(uint256 wTokenId) public view returns(
        string memory sourceChain,
        address contAddr,
        uint256 tokenId,
        string memory name,
        string memory symbol,
        string memory uri
    ) {
        sourceChain = "Ethereum";
        WrappedToken memory wToken = wrappedTokens[wTokenId];
        contAddr = wToken.contAddr;
        tokenId = wToken.tokenId;
        name = wToken.name;
        symbol = wToken.symbol;
        uri = wToken.uri;
    }

    function getFee(
        uint256 wTokenId,
        address to,
        bool payInLink
    ) external view returns (uint256 fee) {
        WrappedToken memory wToken = wrappedTokens[wTokenId];
        uint256 ccipFee = _getFee(wToken.contAddr, to, wToken.tokenId, payInLink);
        return ccipFee * 3/2;
    }
    
    function requestReleaseLockedToken(
        uint256 wTokenId,
        address to,
        address dappAddr
    ) public payable {
        WrappedToken memory wToken = wrappedTokens[wTokenId];

        address contAddr = wToken.contAddr;
        uint256 tokenId = wToken.tokenId;

        require(
            _isApprovedOrOwner(_msgSender(), wTokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(wTokenId);
        bool payInLink = msg.value == 0;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(contAddr, to, tokenId),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payInLink ? i_link : address(0)
        });

        uint256 ccipFee = IRouterClient(i_router).getFee(targetSelector, message);
        uint256 _burnFee = ccipFee / 2;
        uint256 fee = ccipFee + _burnFee;

        bytes32 messageId;
        uint256 feeMATIC;
        if (payInLink) {
            LinkTokenInterface(i_link).transferFrom(msg.sender, address(this), fee);
            burnERC20(LOTT, swap_LINK677_LOTT(_burnFee));
        } else {
            feeMATIC = ccipFee;
            require(msg.value >= fee, "insufficient fee");
            burnERC20(LOTT, swap_MATIC_LOTT(_burnFee));
            if (msg.value > fee) {
                payable(dappAddr).transfer(msg.value - fee);
            }
        }
        messageId = IRouterClient(i_router).ccipSend{value: feeMATIC}(
            targetSelector,
            message
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(CCIPReceiver, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


// internal functions ------------------------------------------------------------------------------

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal virtual override {
        require(
            abi.decode(message.sender, (address)) == address(this) &&
            message.sourceChainSelector == targetSelector,
            "invalid message sender"
        );
        (
            address to,
            address contAddr,
            uint256 tokenId,
            string memory name,
            string memory symbol,
            string memory uri
        ) = abi.decode(message.data, (address, address, uint256, string, string, string));
        _wMint(to, contAddr, tokenId, name, symbol, uri);
    }
    
    function _wMint(
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
}