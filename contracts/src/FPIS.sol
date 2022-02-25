// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FPIShares (FPIS) =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Jack Corddry: https://github.com/corddry

// Reviewer(s) / Contributor(s)
// Sam Sun: https://github.com/samczsun

import "./FraxFinance/Common/Context.sol";
import "./FraxFinance/ERC20/ERC20Custom.sol";
import "./FraxFinance/ERC20/IERC20.sol";
//import "./FraxFinance/Frax/Frax.sol";
import "./FraxFinance/Staking/Owned.sol";
import "./FraxFinance/Math/SafeMath.sol";
import "./FraxFinance/Governance/AccessControl.sol";

contract FPIShares is ERC20Custom, AccessControl, Owned {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public FPIAddress;
    
    uint256 public constant genesis_supply = 100000000e18; // 100M is printed upon genesis

    address public oracle_address;
    address public timelock_address; // Governance timelock address
    FPIContract private FPI; //FPI Contract does not currently exist.

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(FPI.fpi_pools(msg.sender) == true, "Only fpi pools can mint new FPI");
        _;
    } 
    
    modifier onlyByOwnGov() {
        require(msg.sender == owner || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor (
        string memory _name,
        string memory _symbol, 
        address _oracle_address,
        address _creator_address,
        address _timelock_address
    ) public Owned(_creator_address){
        require((_oracle_address != address(0)) && (_timelock_address != address(0)), "Zero address detected"); 
        name = _name;
        symbol = _symbol;
        oracle_address = _oracle_address;
        timelock_address = _timelock_address;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_creator_address, genesis_supply);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setOracle(address new_oracle) external onlyByOwnGov {
        require(new_oracle != address(0), "Zero address detected");

        oracle_address = new_oracle;
    }

    function setTimelock(address new_timelock) external onlyByOwnGov {
        require(new_timelock != address(0), "Timelock address cannot be 0");
        timelock_address = new_timelock;
    }
    
    function setFPIAddress(address fpi_contract_address) external onlyByOwnGov {
        require(fpi_contract_address != address(0), "Zero address detected");

        FPI = FPIContract(fpi_contract_address);

        emit FPIAddressSet(fpi_contract_address);
    }
    
    function mint(address to, uint256 amount) public onlyPools {
        _mint(to, amount);
    }
    
    // This function is what other FPI pools will call to mint new FPIS (similar to the FRAX mint) 
    function pool_mint(address m_address, uint256 m_amount) external onlyPools {        
        super._mint(m_address, m_amount);
        emit FPISMinted(address(this), m_address, m_amount);
    }

    // This function is what other FPI pools will call to burn FPIS 
    function pool_burn_from(address b_address, uint256 b_amount) external onlyPools {
        super._burnFrom(b_address, b_amount);
        emit FPIBurned(b_address, address(this), b_amount);
    }

    /* ========== OVERRIDDEN PUBLIC FUNCTIONS ========== */

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /* ========== EVENTS ========== */

    // Track FXS burned
    event FPISBurned(address indexed from, address indexed to, uint256 amount);

    // Track FXS minted
    event FPISMinted(address indexed from, address indexed to, uint256 amount);

    event FPIAddressSet(address addr);
}