// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "./utils/Swapper.sol";
import "./utils/Burner.sol";

/**
 * ======================================================================
 *   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
 *   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
 *   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
 *   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
 *   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
 * ======================================================================
 *  ================ Open source smart contract on EVM =================
 *   ====================== Using Chainlink CCIP ======================
 * @title Ethereum Cross-Chain NFT Bridge
 * @dev Safely bridge your Ethereum NFTs to Polygon using CCIP V1.
 * To bridge your NFT:
 * a. Approve this contract's address for your NFT.
 * b. Approve Link tokens for the transfer or provide ETH or MATIC for the fee.
 * c. Call `requestReleaseLockedToken` with the required details to initiate the transfer.
 *    - Your NFT will be temporarily locked within this contract.
 *    - In approximately 30 minutes, your NFT will be minted on the Polygon network at the specified address.
 *    - The CCIP transaction ID can be found in the contract logs.
 *    - Your Polygon NFT will have ownership of the original NFT and will be transferable.
 */
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

    /**
     * @dev Constructor to initialize the Ethereum Cross-NFT Bridge.
     * @param _currentSelector The current chain selector.
     * @param _targetSelector The target chain selector.
     * @param router The address of the CCIP router contract.
     * @param link The address of the Link token contract.
     */
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

    /**
     * @dev Get the token URI for a wrapped NFT.
     * @param wTokenId The ID of the wrapped NFT.
     * @return uri The URI of the wrapped NFT.
     */
    function tokenURI(
        uint256 wTokenId
    ) public view override returns (string memory) {
        _requireMinted(wTokenId);
        return (wrappedTokens[wTokenId].uri);
    }

    /**
     * @dev Get information about a wrapped NFT.
     * @param wTokenId The ID of the wrapped NFT.
     * @return sourceChain The source chain where the NFT originated (Ethereum).
     * @return contAddr The address of the original NFT contract.
     * @return tokenId The ID of the original NFT.
     * @return name The name of the original NFT.
     * @return symbol The symbol of the original NFT.
     * @return uri The URI of the original NFT.
     */
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

    /**
     * @dev Get the fee required for releasing a wrapped NFT to another chain.
     * @param wTokenId The ID of the wrapped NFT.
     * @param to The destination address on the other chain.
     * @param payInLink True to pay the fee in Link tokens; false to pay in Matic.
     * @return fee The total fee, including a 50% burn fee.
     */
    function getFee(
        uint256 wTokenId,
        address to,
        bool payInLink
    ) external view returns (uint256 fee) {
        WrappedToken memory wToken = wrappedTokens[wTokenId];
        uint256 ccipFee = _getFee(wToken.contAddr, to, wToken.tokenId, payInLink);
        return ccipFee * 3/2;
    }
    
    /**
     * @dev Request the release of a locked NFT to another chain.
     * @param wTokenId The ID of the wrapped NFT.
     * @param to The destination address on the other chain.
     * @param dappAddr The address of the dapp initiating the transfer.
     * @notice To initiate the NFT transfer, you have two options:
     * 1. Pay the transfer fee in Matic by sending Matic along with this function call.
     * 2. Approve the Link token for transfer to this contract using the Link token's approval function,
     *    then call this function with a value of 0 to pay with your Link tokens.
     * Please ensure you have enough Matic or approved Link tokens to cover the transfer fee.
     */
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

    /**
     * @dev Check if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return True if the contract supports the interface; otherwise, false.
     */
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

    /**
     * @dev Internal function to mint a wrapped NFT (wNFT).
     * @param userAddr The address of the user receiving the wNFT.
     * @param contAddr The address of the original NFT contract.
     * @param tokenId The ID of the original NFT.
     * @param _name The name of the wNFT.
     * @param _symbol The symbol of the wNFT.
     * @param _uri The URI of the wNFT.
     */
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

    /**
     * @dev Internal function to get the fee required for a cross-chain NFT transfer.
     * @param contAddr The address of the NFT contract.
     * @param userAddr The address of the user initiating the transfer.
     * @param tokenId The ID of the NFT being transferred.
     * @param payInLink True if the fee should be paid in Link tokens; false if it should be paid in ETH.
     * @return fee The fee amount required for the transfer.
     */
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