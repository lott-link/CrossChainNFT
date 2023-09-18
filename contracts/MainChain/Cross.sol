// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";


contract Cross is ERC721Holder, CCIPReceiver {
    address immutable i_link;
    uint64 currentSelector;
    uint64 targetSelector;

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
                NFT.symbol()
            ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payInLink ? i_link : address(0)
        });

        // Get the fee required to send the message
        fee = IRouterClient(i_router).getFee(targetSelector, message);
    }

    function requestTransferCrossChain(
        address contAddr,
        address to,
        uint256 tokenId
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
                msg.sender,
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
                payable(msg.sender).transfer(msg.value - fee);
            }
        }
    }

    function _release(
        address contAddr,
        address to,
        uint256 tokenId
    ) internal {
        IERC721 NFT = IERC721(contAddr);
        NFT.safeTransferFrom(address(this), to, tokenId);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal virtual override {
        (
            address contAddr,
            address to,
            uint256 tokenId
        ) = abi.decode(message.data, (address, address, uint256));
        _release(contAddr, to, tokenId);
    }
}