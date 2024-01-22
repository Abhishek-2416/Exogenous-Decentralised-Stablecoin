// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

/**
 * /*
 * @title DSCEngine
 * @author Abhishek Alimchandani
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 * @notice Our DSC System should always be "overcollateralized". At no point , should the value of all collateral <= the value of all the DSC-
 */
import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DSCEngine is ReentrancyGuard {
    ///////////
    //Errors//
    //////////
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressAndPriceFeedAddressesMustBeOfSameLength();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();

    ////////////////////
    //State Variables//
    ///////////////////
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited; //Here we map the address of the user to mapping which consists of the token and the amount of that token deposited

    DecentralisedStableCoin private immutable i_dsc;

    ///////////////////
    //Events         //
    ///////////////////

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    /////////////
    //Modifiers//
    /////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    /////////////
    //Functions//
    /////////////
    constructor(address[] memory tokenAddresss, address[] memory priceFeedAddress, address dscAddress) {
        if (tokenAddresss.length != priceFeedAddress.length) {
            revert DSCEngine__TokenAddressAndPriceFeedAddressesMustBeOfSameLength();
        }

        for (uint256 i = 0; i < tokenAddresss.length; i++) {
            s_priceFeeds[tokenAddresss[i]] = priceFeedAddress[i];
        }
        i_dsc = DecentralisedStableCoin(dscAddress);
    }

    //////////////////////
    //External Functions//
    //////////////////////

    /**
     * @notice This is following the CEI pattern
     * @param tokenCollateralAddress The address of the token to deposit as a collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    // /**
    //  *
    //  * @param amountDscToMint The amount of DSC they would like to mint
    //  */
    // function mintDsc(uint256 amountDscToMint) external {}
}
