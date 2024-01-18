// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title Decentralised Stable Coin
 * @author Abhishek Alimchandani
 * @notice This is a Decentralised Pegged Exogenous Stablecoin
 *
 *
 * This is the contract meant to be goverened by the DSC engine, It is just the ERC20 implementation of our stablecoin system
 */
contract DecentralisedStableCoin is ERC20Burnable, Ownable {
    //Errors
    error DecentralisedStableCoin__AmountMustBeMoreThanZero();
    error DecentralisedStableCoin__BurnAmountExceedsBalance();
    error DecentralisedStableCoin__CannotMintToNullAddress();

    constructor() ERC20("DecentralisedStableCoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralisedStableCoin__AmountMustBeMoreThanZero();
        }

        if (balance < _amount) {
            revert DecentralisedStableCoin__BurnAmountExceedsBalance();
        }

        //This is to call the burn function from the parent class
        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralisedStableCoin__CannotMintToNullAddress();
        }

        if (_amount <= 0) {
            revert DecentralisedStableCoin__AmountMustBeMoreThanZero();
        }

        _mint(_to, _amount);
        return true;
    }
}
