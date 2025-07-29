// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BirthdayContract {
    struct User {
        uint256 birthMonth; // 1-12
        uint256 birthDay;   // 1-31
        uint256 lastClaimedYear; 
        uint256 balance;    // ETH balance of gifts
        bool registered;
    }

    mapping(address => User) private users;

    event Registered(address indexed user, uint256 month, uint256 day);
    event GiftDeposited(address indexed from, address indexed to, uint256 amount);
    event GiftClaimed(address indexed user, uint256 amount, uint256 year);

    modifier isRegistered(address _user) {
        require(users[_user].registered, "User not registered");
        _;
    }

    /// @notice Register your birthday (month/day)
    function registerBirthday(uint256 _month, uint256 _day) external {
        require(_month >= 1 && _month <= 12, "Invalid month");
        require(_day >= 1 && _day <= 31, "Invalid day");
        require(!users[msg.sender].registered, "Already registered");

        users[msg.sender] = User({
            birthMonth: _month,
            birthDay: _day,
            lastClaimedYear: 0,
            balance: 0,
            registered: true
        });

        emit Registered(msg.sender, _month, _day);
    }

    /// @notice Friends can preload ETH gifts
    function depositGift(address _to) external payable isRegistered(_to) {
        require(msg.value > 0, "Gift must be > 0 ETH");
        users[_to].balance += msg.value;
        emit GiftDeposited(msg.sender, _to, msg.value);
    }

    /// @notice Claim your birthday gift (once per year, only on your birthday)
    function claimGift() external isRegistered(msg.sender) {
        User storage user = users[msg.sender];
        require(user.balance > 0, "No gifts available");

        // Extract month/day/year from timestamp
        (uint year, uint month, uint day) = _timestampToDate(block.timestamp);
        require(month == user.birthMonth && day == user.birthDay, "Not your birthday");
        require(year > user.lastClaimedYear, "Already claimed this year");

        uint256 amount = user.balance;
        user.balance = 0;
        user.lastClaimedYear = year;

        payable(msg.sender).transfer(amount);
        emit GiftClaimed(msg.sender, amount, year);
    }

    /// @notice View your gift balance
    function checkGifts() external view isRegistered(msg.sender) returns (uint256) {
        return users[msg.sender].balance;
    }

    /// @dev Convert timestamp to (year, month, day)
    /// Simple algorithm using seconds calculations
    function _timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        uint SECONDS_PER_DAY = 24 * 60 * 60;
        int OFFSET19700101 = 2440588;

        int daysSinceEpoch = int(timestamp / SECONDS_PER_DAY);
        int L = daysSinceEpoch + 68569 + OFFSET19700101;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
}