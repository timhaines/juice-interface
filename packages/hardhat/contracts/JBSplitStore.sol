// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./libraries/Operations2.sol";

// Inheritance
import "./interfaces/IJBSplitsStore.sol";
import "./abstract/Operatable.sol";
import "./abstract/JBTerminalUtility.sol";

/**
  @notice
  Stores splits for each project.
*/
contract JBSplitsStore is IJBSplitsStore, Operatable, JBTerminalUtility {
    // --- private stored properties --- //

    // All splits for each project ID's configurations.
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Split[])))
        private _splitsOf;

    // --- public immutable stored properties --- //

    /// @notice The contract storing project information.
    IProjects public immutable override projects;

    // --- public views --- //

    /**
      @notice 
      Get all splits for the specified project ID.

      @param _projectId The ID of the project to get splits for.
      @param _configuration The configuration to get splits for.
      @param _group The identifying group of the splits.

      @return An array of all splits for the project.
     */
    function get(
        uint256 _projectId,
        uint256 _configuration,
        uint256 _group
    ) external view override returns (Split[] memory) {
        return _splitsOf[_projectId][_configuration][_group];
    }

    // --- constructor --- //

    /** 
      @param _operatorStore A contract storing operator assignments.
      @param _jbDirectory The directory of terminals.
      @param _projects A Projects contract which mints ERC-721's that represent project ownership and transfers.
    */
    constructor(
        IOperatorStore _operatorStore,
        IJBDirectory _jbDirectory,
        IProjects _projects
    ) Operatable(_operatorStore) JBTerminalUtility(_jbDirectory) {
        projects = _projects;
    }

    // --- external transactions --- //

    /** 
      @notice 
      Sets the splits.

      @dev
      Only the owner or operator of a project, or the current terminal of the project, can set its splits.

      @dev
      The new splits must include any currently set splits that are locked.

      @param _projectId The ID of the project to add splits to.
      @param _configuration The funding cycle configuration to set the splits to be active during.
      @param _group The group of splits being set.
      @param _splits The splits to set.
    */
    function set(
        uint256 _projectId,
        uint256 _configuration,
        uint256 _group,
        Split[] memory _splits
    )
        external
        override
        requirePermissionAcceptingAlternateAddress(
            projects.ownerOf(_projectId),
            _projectId,
            Operations2.SetSplits,
            address(directory.terminalOf(_projectId))
        )
    {
        // There must be something to do.
        require(_splits.length > 0, "JBSplitsStore::set: NO_OP");

        // Get a reference to the project's current splits.
        Split[] memory _currentSplits = _splitsOf[_projectId][_configuration][
            _group
        ];

        // Check to see if all locked splits are included.
        for (uint256 _i = 0; _i < _currentSplits.length; _i++) {
            if (block.timestamp < _currentSplits[_i].lockedUntil) {
                bool _includesLocked = false;
                for (uint256 _j = 0; _j < _splits.length; _j++) {
                    // Check for sameness.
                    if (
                        _splits[_j].percent == _currentSplits[_i].percent &&
                        _splits[_j].beneficiary ==
                        _currentSplits[_i].beneficiary &&
                        _splits[_j].allocator == _currentSplits[_i].allocator &&
                        _splits[_j].projectId == _currentSplits[_i].projectId &&
                        // Allow lock extention.
                        _splits[_j].lockedUntil >=
                        _currentSplits[_i].lockedUntil
                    ) _includesLocked = true;
                }
                require(_includesLocked, "JBSplitsStore::set: SOME_LOCKED");
            }
        }

        // Delete from storage so splits can be repopulated.
        delete _splitsOf[_projectId][_configuration][_group];

        // Add up all the percents to make sure they cumulative are under 100%.
        uint256 _percentTotal = 0;

        for (uint256 _i = 0; _i < _splits.length; _i++) {
            // The percent should be greater than 0.
            require(
                _splits[_i].percent > 0,
                "JBSplitsStore::set: BAD_SPLIT_PERCENT"
            );

            // The allocator and the beneficiary shouldn't both be the zero address.
            require(
                _splits[_i].allocator != ISplitAllocator(address(0)) ||
                    _splits[_i].beneficiary != address(0),
                "JBSplitsStore::set: ZERO_ADDRESS"
            );

            // Add to the total percents.
            _percentTotal = _percentTotal + _splits[_i].percent;

            // The total percent should be less than 10000.
            require(
                _percentTotal <= 10000,
                "JBSplitsStore::set: BAD_TOTAL_PERCENT"
            );
            // Push the new split into the project's list of splits.
            _splitsOf[_projectId][_configuration][_group].push(_splits[_i]);

            emit SetSplit(
                _projectId,
                _configuration,
                _group,
                _splits[_i],
                msg.sender
            );
        }
    }
}