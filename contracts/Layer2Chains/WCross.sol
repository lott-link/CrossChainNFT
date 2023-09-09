// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import "./WNFT.sol";

contract WCross is CCIPReceiver {
    uint256 _chainSelector;

    address nftImpl;

    struct WContract {
        uint64 sourceChainSelector;
        address contAddr;
        address wContAddr;
    }
    WContract[] wContracts;

    event WContractCreated(uint256 indexed chainSelector, address sourceAddr, address wAddr);

    constructor(
        uint256 chainSelector,
        address router,
        address link
    ) CCIPReceiver(router) {
        _chainSelector = chainSelector;
        nftImpl = address(new WNFT(address(this), router, link));
    }

    function createWContract(
        uint64 chainSelector, 
        address contractAddr, 
        string memory name, 
        string memory symbol
    ) public returns (address nftAddr) {
        bytes32 salt = keccak256(abi.encode(chainSelector, contractAddr));
        address clone = Clones.predictDeterministicAddress(nftImpl, salt);
        nftAddr = address(WNFT(clone));
        if (clone.code.length == 0) {
            emit WContractCreated(chainSelector, contractAddr, clone);
            Clones.cloneDeterministic(nftImpl, salt);
            WNFT(clone).initialize(name, symbol);
            wContracts.push(WContract(chainSelector, contractAddr, clone));
        }
    }

    function _ccipReceive(
        Client.Any2EVMMessage calldata message
    ) internal virtual override {
        (,address contAddr,,uint64 chainSelector,, string memory name, string memory symbol) = abi.decode(
            message.data[4:], 
            (address, address, address, uint64, uint256, string, string)
        );
        (bool success, ) = createWContract(chainSelector, contAddr, name, symbol).call(message.data[:132]);
        require(success);
    }
}