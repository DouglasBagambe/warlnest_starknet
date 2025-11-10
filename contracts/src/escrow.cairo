#[starknet::contract]
mod Escrow {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess
    };
    use super::super::interfaces::IEscrow;

    #[storage]
    struct Storage {
        // Escrow data
        escrow_seller: Map<u256, ContractAddress>,
        escrow_buyer: Map<u256, ContractAddress>,
        escrow_amount: Map<u256, u256>,
        escrow_property_token: Map<u256, u256>,
        escrow_type: Map<u256, u8>, // 0: booking, 1: deposit, 2: full payment
        escrow_status: Map<u256, u8>, // 0: pending, 1: funded, 2: released, 3: refunded, 4: disputed
        escrow_conditions: Map<u256, ByteArray>,
        escrow_created_at: Map<u256, u64>,
        escrow_disputed: Map<u256, bool>,
        escrow_dispute_reason: Map<u256, ByteArray>,
        
        // Counter
        next_escrow_id: u256,
        
        // Admin for dispute resolution
        admin: ContractAddress,
        arbitrators: Map<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        EscrowCreated: EscrowCreated,
        FundsDeposited: FundsDeposited,
        FundsReleased: FundsReleased,
        FundsRefunded: FundsRefunded,
        DisputeRaised: DisputeRaised,
        DisputeResolved: DisputeResolved,
    }

    #[derive(Drop, starknet::Event)]
    struct EscrowCreated {
        #[key]
        escrow_id: u256,
        #[key]
        property_token_id: u256,
        seller: ContractAddress,
        buyer: ContractAddress,
        amount: u256,
        escrow_type: u8,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct FundsDeposited {
        #[key]
        escrow_id: u256,
        #[key]
        buyer: ContractAddress,
        amount: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct FundsReleased {
        #[key]
        escrow_id: u256,
        #[key]
        seller: ContractAddress,
        amount: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct FundsRefunded {
        #[key]
        escrow_id: u256,
        #[key]
        buyer: ContractAddress,
        amount: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct DisputeRaised {
        #[key]
        escrow_id: u256,
        raised_by: ContractAddress,
        reason: ByteArray,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct DisputeResolved {
        #[key]
        escrow_id: u256,
        resolved_by: ContractAddress,
        released_to_seller: bool,
        timestamp: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
        self.next_escrow_id.write(1);
        self.arbitrators.entry(admin).write(true);
    }

    #[abi(embed_v0)]
    impl EscrowImpl of IEscrow<ContractState> {
        fn create_escrow(
            ref self: ContractState,
            property_token_id: u256,
            buyer: ContractAddress,
            amount: u256,
            escrow_type: u8,
            release_conditions: ByteArray
        ) -> u256 {
            let caller = get_caller_address();
            let escrow_id = self.next_escrow_id.read();
            let timestamp = get_block_timestamp();
            
            assert(buyer.is_non_zero(), 'Invalid buyer address');
            assert(amount > 0, 'Amount must be positive');
            assert(escrow_type <= 2, 'Invalid escrow type');
            
            // Store escrow data
            self.escrow_seller.entry(escrow_id).write(caller);
            self.escrow_buyer.entry(escrow_id).write(buyer);
            self.escrow_amount.entry(escrow_id).write(amount);
            self.escrow_property_token.entry(escrow_id).write(property_token_id);
            self.escrow_type.entry(escrow_id).write(escrow_type);
            self.escrow_status.entry(escrow_id).write(0); // pending
            self.escrow_conditions.entry(escrow_id).write(release_conditions);
            self.escrow_created_at.entry(escrow_id).write(timestamp);
            self.escrow_disputed.entry(escrow_id).write(false);
            
            // Update counter
            self.next_escrow_id.write(escrow_id + 1);
            
            self.emit(EscrowCreated {
                escrow_id,
                property_token_id,
                seller: caller,
                buyer,
                amount,
                escrow_type,
                timestamp,
            });
            
            escrow_id
        }

        fn deposit_funds(ref self: ContractState, escrow_id: u256) {
            let caller = get_caller_address();
            let buyer = self.escrow_buyer.entry(escrow_id).read();
            let status = self.escrow_status.entry(escrow_id).read();
            
            assert(caller == buyer, 'Only buyer can deposit');
            assert(status == 0, 'Escrow not pending');
            
            // In production, this would handle actual token transfers
            // For now, we mark as funded
            self.escrow_status.entry(escrow_id).write(1); // funded
            
            self.emit(FundsDeposited {
                escrow_id,
                buyer: caller,
                amount: self.escrow_amount.entry(escrow_id).read(),
                timestamp: get_block_timestamp(),
            });
        }

        fn release_funds(ref self: ContractState, escrow_id: u256) {
            let caller = get_caller_address();
            let buyer = self.escrow_buyer.entry(escrow_id).read();
            let seller = self.escrow_seller.entry(escrow_id).read();
            let status = self.escrow_status.entry(escrow_id).read();
            let disputed = self.escrow_disputed.entry(escrow_id).read();
            
            assert(caller == buyer || caller == seller, 'Not authorized');
            assert(status == 1, 'Escrow not funded');
            assert(!disputed, 'Escrow is disputed');
            
            // Release funds to seller
            self.escrow_status.entry(escrow_id).write(2); // released
            
            self.emit(FundsReleased {
                escrow_id,
                seller,
                amount: self.escrow_amount.entry(escrow_id).read(),
                timestamp: get_block_timestamp(),
            });
        }

        fn refund_escrow(ref self: ContractState, escrow_id: u256) {
            let caller = get_caller_address();
            let seller = self.escrow_seller.entry(escrow_id).read();
            let buyer = self.escrow_buyer.entry(escrow_id).read();
            let status = self.escrow_status.entry(escrow_id).read();
            
            assert(caller == seller, 'Only seller can refund');
            assert(status == 1, 'Escrow not funded');
            
            // Refund to buyer
            self.escrow_status.entry(escrow_id).write(3); // refunded
            
            self.emit(FundsRefunded {
                escrow_id,
                buyer,
                amount: self.escrow_amount.entry(escrow_id).read(),
                timestamp: get_block_timestamp(),
            });
        }

        fn dispute_escrow(ref self: ContractState, escrow_id: u256, reason: ByteArray) {
            let caller = get_caller_address();
            let buyer = self.escrow_buyer.entry(escrow_id).read();
            let seller = self.escrow_seller.entry(escrow_id).read();
            let status = self.escrow_status.entry(escrow_id).read();
            
            assert(caller == buyer || caller == seller, 'Not authorized');
            assert(status == 1, 'Escrow not funded');
            assert(!self.escrow_disputed.entry(escrow_id).read(), 'Already disputed');
            
            self.escrow_disputed.entry(escrow_id).write(true);
            self.escrow_dispute_reason.entry(escrow_id).write(reason.clone());
            self.escrow_status.entry(escrow_id).write(4); // disputed
            
            self.emit(DisputeRaised {
                escrow_id,
                raised_by: caller,
                reason,
                timestamp: get_block_timestamp(),
            });
        }

        fn resolve_dispute(ref self: ContractState, escrow_id: u256, release_to_seller: bool) {
            let caller = get_caller_address();
            assert(self.arbitrators.entry(caller).read(), 'Not an arbitrator');
            
            let status = self.escrow_status.entry(escrow_id).read();
            assert(status == 4, 'Not disputed');
            
            if release_to_seller {
                self.escrow_status.entry(escrow_id).write(2); // released
            } else {
                self.escrow_status.entry(escrow_id).write(3); // refunded
            }
            
            self.escrow_disputed.entry(escrow_id).write(false);
            
            self.emit(DisputeResolved {
                escrow_id,
                resolved_by: caller,
                released_to_seller,
                timestamp: get_block_timestamp(),
            });
        }

        fn get_escrow_status(self: @ContractState, escrow_id: u256) -> u8 {
            self.escrow_status.entry(escrow_id).read()
        }

        fn get_escrow_amount(self: @ContractState, escrow_id: u256) -> u256 {
            self.escrow_amount.entry(escrow_id).read()
        }

        fn get_escrow_parties(self: @ContractState, escrow_id: u256) -> (ContractAddress, ContractAddress) {
            let seller = self.escrow_seller.entry(escrow_id).read();
            let buyer = self.escrow_buyer.entry(escrow_id).read();
            (seller, buyer)
        }

        fn is_disputed(self: @ContractState, escrow_id: u256) -> bool {
            self.escrow_disputed.entry(escrow_id).read()
        }
    }

    // Admin functions
    #[generate_trait]
    impl AdminImpl of AdminTrait {
        fn add_arbitrator(ref self: ContractState, arbitrator: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Only admin');
            self.arbitrators.entry(arbitrator).write(true);
        }

        fn remove_arbitrator(ref self: ContractState, arbitrator: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Only admin');
            self.arbitrators.entry(arbitrator).write(false);
        }
    }
}
