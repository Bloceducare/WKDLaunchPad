pragma solidity ^0.8.0;
import "./utils/IBEP20.sol";
import "./WKDCommit.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Launchpad is Ownable {
    // The offering token
    IBEP20 offeringToken;
    // check initialized
    bool public isInitialized;
    // The block number when the IFO starts
    uint256 public StartBlock;
    // The block number when the IFO ends
    uint256 public EndBlock;
    // Total amount of offering token to be distributed
    uint256 public totalTokensOffered;
    // pecrcentage of offering token to be distributed for tier 1
    uint256 public tier1Percentage;
    // pecrcentage of offering token to be distributed for tier 2
    uint256 public tier2Percentage;
    // admin address
    address public admin;
    uint256 public raisedAmount;
    // WKDCommit contract
    WKDCommit public wkdCommit;
    // Participants
    address[] public participants;
    // Pools details
    poolCharacteristics public poolsInfo;
    // launchpads share in amount raised
    uint256 public launchPercentShare;
    // Project owner's address
    address public projectOwner;

    struct poolCharacteristics {
        // amount to be raised in BNB
        uint256 raisingAmount;
        // offerinn token
        address offeringToken;
        // amount of offering token to be offered in the pool
        uint256 offeringAmount;
        // amount of WKD commit for tier2
        uint256 minimumRequirementForTier2;
        // launchpad start time
        uint256 launchpadStartTime;
        // launchpad end time
        uint256 launchpadEndTime;
        // Total amount in pool
        uint256 totalAmountInPool;
        // amount of offering token to be shared in tier1
        uint256 tier1Amount;
        // amount of offering token to be shared in tier2
        uint256 tier2Amount;
    }

    enum userTiers {
        Tier1,
        Tier2
    }

    struct userDetails {
        // amoount of BNB deposited by user
        uint256 amountDeposited;
        // user tier
        userTiers userTier;
        // if useer has claimed offering token
        bool hasClaimed;
    }
    mapping(address => userDetails) public user;
    event Deposit(address indexed user, uint256 amount);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event init(
        address indexed offeringToken,
        uint256 StartBlock,
        uint256 EndBlock,
        address admin,
        address wkdCommit
    );
    event Harvest(address indexed user, uint256 offeringTokenAmount);
    event PoolSet( // solhint-disable-next-line func-name-mixedcase
        uint256 raisingAmount,
        address offeringToken,
        uint256 offeringAmount,
        uint256 minimumRequirementForTier2,
        uint256 launchpadStartTime,
        uint256 launchpadEndTime,
        uint256 tier1Amount,
        uint256 tier2Amount
    );

    function initialize(
        address _offeringToken,
        uint256 _startBlock,
        uint256 _endBlock,
        address _adminAddress,
        address _wkdCommit
    ) public {
        require(msg.sender == owner(), "Launchpad: FORBIDDEN");
        require(!isInitialized, "Launchpad: already initialized");
        offeringToken = IBEP20(_offeringToken);
        isInitialized = true;
        StartBlock = _startBlock;
        EndBlock = _endBlock;
        admin = _adminAddress;
        wkdCommit = WKDCommit(_wkdCommit);
        emit init(_offeringToken, _startBlock, _endBlock, _adminAddress, _wkdCommit);
    }

    function setPool(
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        uint256 _launchPercentShare,
        uint256 _tier2Percentage,
        uint256 _minimumRequirementForTier2
        
    ) public {
        require(msg.sender == admin, "Launchpad: only admin can set pool");
        require(block.number < StartBlock, "Launchpad: Pool already started");
        require(
            _launchPercentShare <= 100,
            "Launchpad: Launchpad share cannot be more than 100%"
        );
        require(
            _tier2Percentage <= 100,
            "Launchpad: Tier2 share cannot be more than 100%"
        );
        offeringToken.transferFrom(msg.sender, address(this), _offeringAmount);
        require(
            offeringToken.balanceOf(address(this)) >= _offeringAmount,
            "Launchpad: insufficient offering token balance"
        );
        poolsInfo.offeringAmount = _offeringAmount;
        poolsInfo.raisingAmount = _raisingAmount;
        launchPercentShare = _launchPercentShare;
        poolsInfo.minimumRequirementForTier2 = _minimumRequirementForTier2;
        tier2Percentage = _tier2Percentage;
        tier1Percentage = 100 - _tier2Percentage;
        poolsInfo.tier2Amount = _offeringAmount *( _tier2Percentage / 100);
        poolsInfo.tier1Amount = _offeringAmount * (100 - _tier2Percentage) / 100;
       
        emit PoolSet(
            _raisingAmount,
            address(offeringToken),
            _offeringAmount,
            _minimumRequirementForTier2,
            StartBlock,
            EndBlock,
            poolsInfo.tier1Amount,
            poolsInfo.tier2Amount
        );

    }

    function deposit() public payable {
        require(isInitialized, "Launchpad: Contract not initialized");
        require(block.number >= StartBlock, "Launchpad: IFO has not started");
        require(block.number <= EndBlock, "Launchpad: IFO has ended");
        require(
            poolsInfo.raisingAmount <= raisedAmount,
            "Launchpad: Target completed"
        );
        uint256 userCommit = wkdCommit.getUserCommit(msg.sender);
        require(userCommit > 0, "Launchpad: No WKD commit");
        require(msg.value > 0, "Launchpad: Amount must be greater than 0");

        if (userCommit >= poolsInfo.minimumRequirementForTier2) {
            user[msg.sender].userTier = userTiers.Tier2;
        } else {
            user[msg.sender].userTier = userTiers.Tier1;
        }
        participants.push(msg.sender);
        user[msg.sender].amountDeposited += msg.value;
        raisedAmount += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function harvestPool() public {
        require(isInitialized, "Launchpad: Contract not initialized");
        require(block.number >= EndBlock, "Launchpad: IFO has not ended");
        require(
            user[msg.sender].amountDeposited > 0,
            "Launchpad: User has not deposited"
        );
        require(
            !user[msg.sender].hasClaimed,
            "Launchpad: User has already claimed"
        );
        if (user[msg.sender].userTier == userTiers.Tier1) {
            uint256 offeringTokenAmount =
                (user[msg.sender].amountDeposited/raisedAmount) * poolsInfo.tier1Amount;
            offeringToken.transfer(msg.sender, offeringTokenAmount);
            user[msg.sender].hasClaimed = true;
            emit Harvest(msg.sender, offeringTokenAmount);
        } else if (user[msg.sender].userTier == userTiers.Tier2) {
            uint256 offeringTokenAmount =
                (user[msg.sender].amountDeposited/raisedAmount) * poolsInfo.tier2Amount;
            offeringToken.transfer(msg.sender, offeringTokenAmount);
            user[msg.sender].hasClaimed = true;
            emit Harvest(msg.sender, offeringTokenAmount);
        }

    }

    function finalWithdraw(uint256 offerringAmount, uint256 BNBAmount)
        external
        onlyOwner
    {
        require(msg.sender == admin, "Launchpad: Only admin can withdraw");
        require(
            offerringAmount <= offeringToken.balanceOf(address(this)),
            "Launchpad: Insufficient balance"
        );
        require(
            BNBAmount <= address(this).balance,
            "Launchpad: Insufficient balance"
        );

        uint256 BnbBalance = address(this).balance;
        uint256 LaunchpadShares = (launchPercentShare / 100) * BnbBalance;
        uint256 projectOwnerShares = BnbBalance - LaunchpadShares;
        payable(projectOwner).transfer(projectOwnerShares);
        payable(admin).transfer(LaunchpadShares);
        offeringToken.transfer(msg.sender, offerringAmount);
    }

    // allocation 100000 means 0.1(10%), 1 meanss 0.000001(0.0001%), 1000000 means 1(100%)
    function getUserAllocation(address _user) public view returns (uint256) {
        return (user[_user].amountDeposited * 1e12) / (raisedAmount / 1e6);
    }

    // get the amount of offering token to be distributed to user
    function getOfferingTokenAmount(address _user)
        public
        view
        returns (uint256)
    {
        return
            (user[_user].amountDeposited * poolsInfo.offeringAmount) /
            poolsInfo.raisingAmount;
    }

    function hasHarvested(address _user) public view returns (bool) {
        return user[_user].hasClaimed;
    }

    function getParticipantsLength() public view returns (uint256) {
        return participants.length;
    }
    function getUserTier(address _user) public view returns (userTiers) {
        return user[_user].userTier;
    }
   function getTier1Amount() public view returns (uint256) {
        return poolsInfo.tier1Amount;
    }
    function getUserDeposit() public view returns (uint256) {
        return user[msg.sender].amountDeposited;
    }
    // Calculate amount of offering token to be distributed in tier2
    function getTier2Amount() public view returns (uint256) {
        return poolsInfo.tier2Amount;
    }


     /**
     * @notice Get current Time
     */
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    receive() external payable {
        deposit();
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
    {
        require(
            _tokenAddress != address(offeringToken),
            "Recover: Cannot be offering token"
        );

        IBEP20(_tokenAddress).transfer(msg.sender, _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
}
