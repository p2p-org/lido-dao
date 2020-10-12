pragma solidity 0.4.24;

contract OracleMinimalMock {
    address owner;
    struct Report {
        uint256 interval;
        uint256 balance;
    }
    mapping(uint256 => Report) public currentlyAggregatedData;
    uint256 index = 0;
    event DataPushed(uint256 indexed _index, uint256 _interval, uint256 balance);


    function OracleMinimalMock() public {
        owner = msg.sender;
    }

    modifier onlyOwner () {
      require(msg.sender == owner, "NOT OWNER");
      _;
    }

    /**
      * @notice pushData mock
      * @param _reportInterval any positive value
      * @param _eth2balance any value
      */
    function pushData(uint256 _reportInterval, uint256 _eth2balance) external onlyOwner {
        require(currentlyAggregatedData[index-1].interval < _reportInterval, "REPORT_INTERVAL_IS_TOO_OLD");

        currentlyAggregatedData[index] = Report(_reportInterval, _eth2balance);
        emit DataPushed(index, _reportInterval, _eth2balance);
        index++;
    }

    /**
      * @notice Debug function
      * @param _index Index to rewrite
      * @param _reportInterval ReportInterval to rewrite
      * @param _eth2balance Balance to rewrite
      */
    function setReport(uint256 _index, uint256 _reportInterval, uint256 _eth2balance) public onlyOwner {
        currentlyAggregatedData[_index] = Report(_reportInterval, _eth2balance);
    }
}
