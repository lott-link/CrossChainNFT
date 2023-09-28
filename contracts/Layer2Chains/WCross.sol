// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./WNFT.sol";
import "./utils/Swapper.sol";
import "./utils/Burner.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Etherume_Cross_NFT is Ownable, Swapper, Burner, WNFT, ReentrancyGuard {

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
        uint256 ccipFee = _getFee(wToken.contAddr, userAddr, wToken.tokenId, payInLink);
        (uint256 _dappFee, uint256 _burnFee) = getFeeShares(ccipFee); 
        return ccipFee + _dappFee + _burnFee;
    }
    
    function requestReleaseLockedToken(
        uint256 wTokenId,
        address to,
        address dappAddr
    ) public payable nonReentrant {
        WrappedToken memory wToken = wrappedTokens[wTokenId];

        address contAddr = wToken.contAddr;
        uint256 tokenId = wToken.tokenId;

        require(
            _isApprovedOrOwner(_msgSender(), wTokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(wTokenId);
        delete wrappedTokens[wTokenId];
        bool payInLink = msg.value == 0;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encode(contAddr, to, tokenId),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: payInLink ? i_link : address(0)
        });

        uint256 ccipFee = IRouterClient(i_router).getFee(targetSelector, message);
        (uint256 _dappFee, uint256 _burnFee) = getFeeShares(ccipFee); 
        uint256 fee = ccipFee + _dappFee + _burnFee;

        bytes32 messageId;
        uint256 feeMATIC;
        if (payInLink) {
            feeMATIC = ccipFee;
            LinkTokenInterface(i_link).transferFrom(msg.sender, address(this), fee);
            _payLINK(dappAddr, _dappFee);
            burnERC20(LOTT, swap_LINK677_LOTT(_burnFee));
        } else {
            require(msg.value >= fee, "insufficient fee");
            _payMATIC(dappAddr, _dappFee);
            burnERC20(LOTT, swap_MATIC_LOTT(_burnFee));
            if (msg.value > fee) {
                payable(msg.sender).transfer(msg.value - fee);
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

// administration --------------------------------------------------------------------------
    uint256 constant public denominator = 10000;
    uint256 public dappFeeShare;
    uint256 public burnFeeShare;

    function setFee(uint256 _dappFeeShare, uint256 _burnFeeShare) public onlyOwner {
        dappFeeShare = _dappFeeShare;
        burnFeeShare = _burnFeeShare;
    }

    function getFeeShares(uint256 ccipFee) public view returns(uint256 _dappFee, uint256 _burnFee){
        _burnFee = ccipFee * burnFeeShare / denominator;
        _dappFee = ccipFee * dappFeeShare / denominator;
    }

    function _payLINK(address addr, uint256 amount) internal {
        LinkTokenInterface(i_link).transfer(addr, amount);
    }

    function _payMATIC(address addr, uint256 amount) internal {
        payable(addr).transfer(amount);
    }

    function load_LINK_LOTT(uint256 amountLINK) internal {
        uint256 amountLOTT = swap_LINK677_LOTT(amountLINK);
        burnERC20(LOTT, amountLOTT);
    }

    function load_MATIC_LOTT(uint256 amountMATIC) internal {
        uint256 amountLOTT = swap_MATIC_LOTT(amountMATIC);
        burnERC20(LOTT, amountLOTT);
    }
}