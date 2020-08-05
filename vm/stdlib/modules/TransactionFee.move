address 0x1 {

module TransactionFee {
    use 0x1::Token::{Self, Token};
    use 0x1::CoreAddresses;
    use 0x1::Signer;
    use 0x1::STC::{STC};
    use 0x1::Timestamp;
    use 0x1::ErrorCode;

    /// The `TransactionFee` resource holds a preburn resource for each
    /// fiat `TokenType` that can be collected as a transaction fee.
    resource struct TransactionFee<TokenType> {
        fee: Token<TokenType>,
    }

    /// Called in genesis. Sets up the needed resources to collect transaction fees from the
    /// `TransactionFee` resource with the TreasuryCompliance account.
    public fun initialize(
        account: &signer,
    ) {
        assert(Timestamp::is_genesis(), ErrorCode::ENOT_GENESIS());
        assert(Signer::address_of(account) == CoreAddresses::GENESIS_ADDRESS(), ErrorCode::ENOT_GENESIS_ACCOUNT());

        // accept fees in all the currencies
        add_txn_fee_token<STC>(account);
    }

    /// publishing a wrapper of the `Preburn<TokenType>` resource under `fee_account`
    fun add_txn_fee_token<TokenType>(
        account: &signer,
    ) {
        move_to(
            account,
            TransactionFee<TokenType> {
                fee: Token::zero(),
            }
        )
     }

    /// Deposit `token` into the transaction fees bucket
    public fun pay_fee<TokenType>(token: Token<TokenType>) acquires TransactionFee {
        let txn_fees = borrow_global_mut<TransactionFee<TokenType>>(
            CoreAddresses::GENESIS_ADDRESS()
        );
        Token::deposit(&mut txn_fees.fee, token)
    }

    /// Distribute the transaction fees collected in the `TokenType` token.
    /// If the `TokenType` is STC, it unpacks the token and preburns the
    /// underlying fiat.
    public fun distribute_transaction_fees<TokenType>(
        account: &signer,
    ): Token<TokenType> acquires TransactionFee {
        let fee_address =  CoreAddresses::GENESIS_ADDRESS();
        assert(Signer::address_of(account) == fee_address, ErrorCode::ENOT_GENESIS_ACCOUNT());

        // extract fees
        let txn_fees = borrow_global_mut<TransactionFee<TokenType>>(fee_address);
        let value = Token::value<TokenType>(&txn_fees.fee);
        if (value > 0) {
            Token::withdraw(&mut txn_fees.fee, value)
        }else {
            Token::zero<TokenType>()
        }
    }
 }
}
