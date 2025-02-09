# Milestone Funding Contract

A smart contract for managing crowd-funded project milestones on the Stacks blockchain.

## Features

- Project owners can create milestones with funding requirements and voting thresholds
- Contributors can fund specific milestones
- Community voting system for milestone completion approval
- Funds are held in escrow until milestone completion
- Time-based refund window for contributors with block height tracking
- Project owners can mark milestones as complete after reaching vote threshold
- Built-in verification and security checks
- Individual contribution tracking

## Contract Functions

- add-milestone: Add a new project milestone with funding requirement and vote threshold
- fund-milestone: Fund a specific milestone
- vote-milestone: Vote for milestone completion
- complete-milestone: Mark a milestone as complete (requires vote threshold)
- request-refund: Request refund during refund period (now tracked per milestone)
- get-milestone: Get milestone details
- get-total-funds: Get total funds in contract
- get-current-milestone: Get current milestone count
- get-funder-contribution: Get specific funder's contribution amount

## Voting System

Each milestone now requires a minimum number of community votes before it can be marked as complete. This ensures community oversight and increases transparency.

## Refund Mechanism

Contributors can request refunds within a specified time window after funding a milestone. The refund period is now tracked individually for each milestone based on its funding block height. This provides more accurate and fair refund windows for contributors.

### Recent Updates

- Added per-milestone refund period tracking
- Improved refund validation checks
- Added new error code for expired refund periods
- Enhanced milestone data structure with funded-block tracking
