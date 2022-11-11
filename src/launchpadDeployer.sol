pragma solidity ^0.8.0;

import "./utils/IBEP20.sol";
import "../src/launchpad.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract LaunchpadDeployer is Ownable {
    event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);
    event NewIFOContract(address indexed ifoAddress);

    function createLaunchpad(
        address _offeringToken,
        uint256 _startBlock,
        uint256 _endBlock,
        address _adminAddress,
        address _projectOwner,
        address _wkdCommit,
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        uint256 _launchPercentShare,
        uint256 _tier2Percentage,
        uint256 _minimumRequirementForTier2
    ) external onlyOwner {
        require(IBEP20(_offeringToken).totalSupply() > 0, "Invalid token address");
        require(_startBlock > block.number, "Invalid start block");
        require(_endBlock > _startBlock, "Invalid end block");
        require(_adminAddress != address(0), "Invalid admin address");
        require(_wkdCommit != address(0), "Invalid wkdCommit address");
        bytes memory bytecode = type(Launchpad).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_offeringToken, _startBlock));
        address payable launchpadAddress;
        assembly {
            launchpadAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        Launchpad(launchpadAddress).initialize(
            _offeringToken,
            _startBlock,
            _endBlock,
            _adminAddress,
            _projectOwner,
            _wkdCommit,
            _offeringAmount,
            _raisingAmount,
            _launchPercentShare,
            _tier2Percentage,
            _minimumRequirementForTier2

        );
        emit NewIFOContract(launchpadAddress);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress) external onlyOwner {
        uint256 balanceToRecover = IBEP20(_tokenAddress).balanceOf(address(this));
        require(balanceToRecover > 0, "Operations: Balance must be > 0");
        IBEP20(_tokenAddress).transfer(address(msg.sender), balanceToRecover);

        emit AdminTokenRecovery(_tokenAddress, balanceToRecover);
    }
}
