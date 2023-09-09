// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";


contract Cross is ERC721Holder {

    address immutable i_router;
    address immutable i_link;
    uint64 immutable _chainSelector;

    modifier onlyRouter() {
        require(msg.sender == i_router, "onlyRouter");
        _;
    }

    constructor(address router, address link, uint64 chainSelector) {
        i_router = router;
        i_link = link;
        _chainSelector = chainSelector;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);
    }

    function getFee(
        uint64 targetChainSelector,
        address userAddr,
        address contAddr,
        uint256 tokenId,
        address wAddr,
        bool payInLink
    ) external view returns (uint256 fee) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        IERC721Metadata NFT = IERC721Metadata(contAddr);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(wAddr),
            data: abi.encodeWithSignature(
                "wMint(address,address,uint256,uint64)", 
                userAddr, contAddr, tokenId, _chainSelector, address(this), NFT.name(), NFT.symbol()
            ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payInLink ? i_link : address(0)
        });

        // Get the fee required to send the message
        fee = IRouterClient(i_router).getFee(targetChainSelector, message);
    }

    function xTransfer(
        uint64 targetChainSelector,
        address contAddr,
        uint256 tokenId,
        address wAddr
    ) public payable {

        bool payInLink = msg.value == 0;
        address userAddr = msg.sender;

        IERC721Metadata NFT = IERC721Metadata(contAddr);
        NFT.safeTransferFrom(userAddr, address(this), tokenId);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(wAddr),
            data: abi.encodeWithSignature(
                "wMint(address,address,uint256,uint64)", 
                userAddr, contAddr, tokenId, _chainSelector, address(this), NFT.name(), NFT.symbol()
            ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payInLink ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            targetChainSelector,
            message
        );

        bytes32 messageId;

        if (payInLink) {
            LinkTokenInterface(i_link).transferFrom(msg.sender, address(this), fee);
            messageId = IRouterClient(i_router).ccipSend(
                targetChainSelector,
                message
            );
        } else {
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                targetChainSelector,
                message
            );
        }
    }

    function release(address contAddr, address to, uint256 tokenId) public onlyRouter {
        IERC721 NFT = IERC721(contAddr);
        NFT.safeTransferFrom(address(this), to, tokenId);
    }
}