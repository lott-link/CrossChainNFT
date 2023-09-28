// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

/**
 * @title NFT Cross-Chain Bridge to Polygon Powered By CCIP V1
 * @dev This smart contract provides a secure bridge for transferring NFTs from Ethereum to Polygon.
 * To use this bridge:
 * a. Approve your NFT to the address of this contract.
 * b. Approve your Link token to this contract or provide ETH for the transfer fee.
 * c. Call the `requestTransferCrossChain` function with the required data to initiate the transfer process.
 *    - Your NFT will be locked in this contract.
 *    - After approximately 30 minutes, your NFT will be minted on the Polygon network at the specified address.
 *    - You can find the CCIP transaction ID in the contract logs.
 *    - Your Polygon NFT will own the original NFT and will be transferable.
 */
contract Polygon_NFT_Bridge is ERC721Holder, CCIPReceiver {
    address immutable i_link;
    uint64 currentSelector;
    uint64 targetSelector;

    /**
     * @dev Constructor to initialize the bridge contract.
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
    ) CCIPReceiver(router) {
        currentSelector = _currentSelector;
        targetSelector = _targetSelector;
        i_link = link;
        LinkTokenInterface(link).approve(i_router, type(uint256).max);
    }

    /**
     * @dev Get the fee required for a cross-chain NFT transfer.
     * @param userAddr The address of the user initiating the transfer.
     * @param contAddr The address of the NFT contract.
     * @param tokenId The ID of the NFT being transferred.
     * @param payInLink True if the fee should be paid in Link tokens; false if it should be paid in ETH.
     * @return fee The fee amount required for the transfer.
     */
    function getFee(
        address userAddr,
        address contAddr,
        uint256 tokenId,
        bool payInLink
    ) external view returns (uint256 fee) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        IERC721Metadata NFT = IERC721Metadata(contAddr);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(
                userAddr,
                contAddr,
                tokenId,
                NFT.name(),
                NFT.symbol(),
                NFT.tokenURI(tokenId)
            ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payInLink ? i_link : address(0)
        });

        // Get the fee required to send the message
        fee = IRouterClient(i_router).getFee(targetSelector, message);
    }

    /**
     * @dev Request the cross-chain transfer of an NFT.
     * @param contAddr The address of the NFT contract.
     * @param to The address where the NFT will be minted on the Polygon network.
     * @param tokenId The ID of the NFT being transferred.
     * @param dappAddr The address of the dapp initiating the transfer.
     * @notice To initiate the NFT transfer, you have two options:
     * 1. Pay the transfer fee in ETH by sending ETH along with this function call.
     * 2. Approve the Link token for transfer to this contract using the Link token's approval function.
     * Please ensure you have enough ETH or approved Link tokens to cover the transfer fee.
     */
    function requestTransferCrossChain(
        address contAddr,
        address to,
        uint256 tokenId,
        address dappAddr
    ) public payable {
        bool payInLink = msg.value == 0;
        address from = msg.sender;

        IERC721Metadata NFT = IERC721Metadata(contAddr);
        NFT.safeTransferFrom(from, address(this), tokenId);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(
                to,
                contAddr,
                tokenId,
                NFT.name(),
                NFT.symbol(),
                NFT.tokenURI(tokenId)
            ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payInLink ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            targetSelector,
            message
        );

        bytes32 messageId;

        if (payInLink) {
            LinkTokenInterface(i_link).transferFrom(
                from,
                address(this),
                fee
            );
            messageId = IRouterClient(i_router).ccipSend(
                targetSelector,
                message
            );
        } else {
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                targetSelector,
                message
            );
            if (msg.value > fee) {
                payable(dappAddr).transfer(msg.value - fee);
            }
        }
    }


    /**
     * @dev Internal function to release an NFT to the specified recipient.
     * @param contAddr The address of the NFT contract.
     * @param to The address where the NFT will be minted on the Polygon network.
     * @param tokenId The ID of the NFT being transferred.
     */
    function _release(
        address contAddr,
        address to,
        uint256 tokenId
    ) internal {
        IERC721 NFT = IERC721(contAddr);
        NFT.safeTransferFrom(address(this), to, tokenId);
    }

    /**
     * @dev Internal function to handle the receipt of a cross-chain message.
     * @param message The cross-chain message received.
     */
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal virtual override {
        require(
            abi.decode(message.sender, (address)) == address(this) &&
            message.sourceChainSelector == targetSelector,
            "invalid message sender"
        );
        (
            address contAddr,
            address to,
            uint256 tokenId
        ) = abi.decode(message.data, (address, address, uint256));
        _release(contAddr, to, tokenId);
    }
}
