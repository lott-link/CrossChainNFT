// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract WNFT is  Initializable, ERC721BurnableUpgradeable {

    address immutable i_router;
    address immutable i_link;
    address immutable _wCross;

    struct Token {
        address contAddr;
        uint256 tokenId;
        uint64 chainSelector;
    }
    mapping(uint256 => Token) tokens;

    modifier onlyWCross() {
        require(msg.sender == _wCross, "only wCross");
        _;
    }
    function initialize(string memory _name, string memory _symbole) public initializer {
        __ERC721_init(string.concat("wrapped ", _name), string.concat("w" ,_symbole));
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);
    }

    constructor(
        address wCross,
        address router,
        address link
    ) {
        _wCross = wCross; 
        i_router = router;
        i_link = link;
    }

    function getFee(
        uint64 targetChainSelector,
        address userAddr,
        uint256 wTokenId,
        bool payInLink
    ) external view returns (uint256 fee) {
        Token memory token = tokens[wTokenId];

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(userAddr),
            data: abi.encodeWithSignature(
                "release(address,address,uint256)",
                token.contAddr,
                userAddr,
                token.tokenId
            ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payInLink ? i_link : address(0)
        });

        // Get the fee required to send the message
        fee = IRouterClient(i_router).getFee(targetChainSelector, message);
    }
    
    function wMint(
        address userAddr,
        address contAddr,
        uint256 tokenId,
        uint64 chainSelector
    ) public onlyWCross {
        uint256 wTokenId = uint64(
            uint256(
                keccak256(abi.encodePacked(tokenId, contAddr, chainSelector))
            )
        );
        tokens[wTokenId] = Token(contAddr, tokenId, chainSelector);

        _safeMint(userAddr, tokenId);
    }

    // function xBack(uint256 wTokenId) public payable {
    //     _requireMinted(wTokenId);
    //     Token memory token = tokens[wTokenId];
    //     address userAddr = msg.sender;

    //     bool payInLink = msg.value == 0;

    //     burn(wTokenId);

    //     Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
    //         receiver: abi.encode(token.crossAddr),
    //         data: abi.encodeWithSignature(
    //             "release(address,address,uint256)",
    //             token.contAddr,
    //             userAddr,
    //             token.tokenId
    //         ),
    //         tokenAmounts: new Client.EVMTokenAmount[](0),
    //         extraArgs: "",
    //         feeToken: payInLink ? i_link : address(0)
    //     });

    //     uint256 fee = IRouterClient(i_router).getFee(
    //         token.chainSelector,
    //         message
    //     );

    //     bytes32 messageId;

    //     if (payInLink) {
    //         LinkTokenInterface(i_link).transferFrom(
    //             msg.sender,
    //             address(this),
    //             fee
    //         );
    //         messageId = IRouterClient(i_router).ccipSend(
    //             token.chainSelector,
    //             message
    //         );
    //     } else {
    //         messageId = IRouterClient(i_router).ccipSend{value: fee}(
    //             token.chainSelector,
    //             message
    //         );
    //     }
    // }
        
}