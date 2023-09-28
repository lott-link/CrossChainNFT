// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./WNFT.sol";
import "./utils/Swapper.sol";
import "./utils/Burner.sol";

contract Ethereum_Cross_NFT is Swapper, Burner, WNFT {

    constructor(
        uint64 _currentSelector,
        uint64 _targetSelector,
        address router,
        address link
    ) WNFT(router, link) {
        currentSelector = _currentSelector;
        targetSelector = _targetSelector;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);
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
            string memory tokenURI
        ) = abi.decode(message.data, (address, address, uint256, string, string, string));
        wMint(to, contAddr, tokenId, name, symbol, tokenURI);
    }

}