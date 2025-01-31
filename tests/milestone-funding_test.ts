import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can add milestone with voting threshold",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('milestone-funding', 'add-milestone', [
                types.ascii("Build MVP"),
                types.uint(1000),
                types.uint(5)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
        
        let milestone = chain.callReadOnlyFn(
            'milestone-funding',
            'get-milestone',
            [types.uint(1)],
            deployer.address
        );
        
        milestone.result.expectSome().expectTuple({
            'description': types.ascii("Build MVP"),
            'funds-required': types.uint(1000),
            'completed': types.bool(false),
            'funded': types.bool(false),
            'vote-count': types.uint(0),
            'vote-threshold': types.uint(5)
        });
    }
});

Clarinet.test({
    name: "Can vote on milestone",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const voter = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('milestone-funding', 'add-milestone', [
                types.ascii("Build MVP"),
                types.uint(1000),
                types.uint(5)
            ], deployer.address),
            Tx.contractCall('milestone-funding', 'vote-milestone', [
                types.uint(1)
            ], voter.address)
        ]);
        
        block.receipts.map(receipt => receipt.result.expectOk());
        
        let milestone = chain.callReadOnlyFn(
            'milestone-funding',
            'get-milestone',
            [types.uint(1)],
            deployer.address
        );
        
        milestone.result.expectSome().expectTuple({
            'description': types.ascii("Build MVP"),
            'funds-required': types.uint(1000),
            'completed': types.bool(false),
            'funded': types.bool(false),
            'vote-count': types.uint(1),
            'vote-threshold': types.uint(5)
        });
    }
});

Clarinet.test({
    name: "Cannot complete milestone without sufficient votes",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const funder = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('milestone-funding', 'add-milestone', [
                types.ascii("Build MVP"),
                types.uint(1000),
                types.uint(5)
            ], deployer.address),
            Tx.contractCall('milestone-funding', 'fund-milestone', [
                types.uint(1)
            ], funder.address),
            Tx.contractCall('milestone-funding', 'complete-milestone', [
                types.uint(1)
            ], deployer.address)
        ]);
        
        block.receipts[2].result.expectErr().expectUint(103);
    }
});
