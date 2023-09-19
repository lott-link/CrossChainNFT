// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./WNFT.sol";

contract WCross is WNFT {

    event CcipReceive(bytes data);

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
        address userAddr,
        uint256 wTokenId,
        bool payInLink
    ) external view returns (uint256 fee) {
        WrappedToken memory wToken = wrappedTokens[wTokenId];
        return _getFee(wToken.contAddr, userAddr, wToken.tokenId, payInLink);
    }
        
    
    // age user ezafi pool dad baqiasho behesh bargardoonim.
    // ye meqdar ham ezafe tar begirim baqiasho bedim be dapp.
    function requestReleaseLockedToken(
        uint256 wTokenId,
        address to
    ) public payable {
        WrappedToken memory wToken = wrappedTokens[wTokenId];

        address contAddr = wToken.contAddr;
        uint256 tokenId = wToken.tokenId;

        require(
            _isApprovedOrOwner(_msgSender(), wTokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(wTokenId);
        delete wrappedTokens[wTokenId];

        xBack(contAddr, to, tokenId);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal virtual override {
        require(
            abi.decode(message.sender, (address)) == address(this),
            "invalid message sender address"
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
        emit CcipReceive(msg.data);
    }
}