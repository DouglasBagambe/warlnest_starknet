#[starknet::contract]
mod PropertyRegistry {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess
    };
    use super::super::interfaces::IPropertyRegistry;

    #[storage]
    struct Storage {
        // Property ownership and metadata
        property_owners: Map<u256, ContractAddress>,
        property_metadata: Map<u256, ByteArray>,
        property_prices: Map<u256, u256>,
        property_types: Map<u256, u8>,
        property_locations: Map<u256, felt252>,
        
        // Verification system
        verified_properties: Map<u256, bool>,
        verification_timestamps: Map<u256, u64>,
        verifiers: Map<u256, ContractAddress>,
        
        // Property history tracking
        property_history_count: Map<u256, u256>,
        property_history: Map<(u256, u256), ContractAddress>, // (token_id, index) -> owner
        
        // Mapping from property_id to token_id
        property_id_to_token: Map<felt252, u256>,
        
        // Counter for token IDs
        next_token_id: u256,
        total_supply: u256,
        
        // Admin and authorized verifiers
        admin: ContractAddress,
        authorized_verifiers: Map<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PropertyMinted: PropertyMinted,
        PropertyVerified: PropertyVerified,
        PropertyTransferred: PropertyTransferred,
        PriceUpdated: PriceUpdated,
        MetadataUpdated: MetadataUpdated,
        VerifierAuthorized: VerifierAuthorized,
        VerifierRevoked: VerifierRevoked,
    }

    #[derive(Drop, starknet::Event)]
    struct PropertyMinted {
        #[key]
        token_id: u256,
        #[key]
        property_id: felt252,
        #[key]
        owner: ContractAddress,
        price: u256,
        property_type: u8,
        location_hash: felt252,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct PropertyVerified {
        #[key]
        token_id: u256,
        #[key]
        verifier: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct PropertyTransferred {
        #[key]
        token_id: u256,
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct PriceUpdated {
        #[key]
        token_id: u256,
        old_price: u256,
        new_price: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct MetadataUpdated {
        #[key]
        token_id: u256,
        new_metadata_uri: ByteArray,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct VerifierAuthorized {
        #[key]
        verifier: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct VerifierRevoked {
        #[key]
        verifier: ContractAddress,
        timestamp: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
        self.next_token_id.write(1);
        self.total_supply.write(0);
        self.authorized_verifiers.entry(admin).write(true);
    }

    #[abi(embed_v0)]
    impl PropertyRegistryImpl of IPropertyRegistry<ContractState> {
        fn mint_property(
            ref self: ContractState,
            property_id: felt252,
            owner: ContractAddress,
            metadata_uri: ByteArray,
            price: u256,
            property_type: u8,
            location_hash: felt252
        ) -> u256 {
            // Check if property_id already exists
            let existing_token = self.property_id_to_token.entry(property_id).read();
            assert(existing_token == 0, 'Property already exists');
            
            let token_id = self.next_token_id.read();
            let timestamp = get_block_timestamp();
            
            // Store property data
            self.property_owners.entry(token_id).write(owner);
            self.property_metadata.entry(token_id).write(metadata_uri.clone());
            self.property_prices.entry(token_id).write(price);
            self.property_types.entry(token_id).write(property_type);
            self.property_locations.entry(token_id).write(location_hash);
            self.property_id_to_token.entry(property_id).write(token_id);
            
            // Initialize history
            self.property_history.entry((token_id, 0)).write(owner);
            self.property_history_count.entry(token_id).write(1);
            
            // Update counters
            self.next_token_id.write(token_id + 1);
            self.total_supply.write(self.total_supply.read() + 1);
            
            // Emit event
            self.emit(PropertyMinted {
                token_id,
                property_id,
                owner,
                price,
                property_type,
                location_hash,
                timestamp,
            });
            
            token_id
        }

        fn verify_property(ref self: ContractState, token_id: u256, verifier: ContractAddress) {
            // Only authorized verifiers can verify
            assert(self.authorized_verifiers.entry(verifier).read(), 'Not authorized verifier');
            assert(self.property_owners.entry(token_id).read().is_non_zero(), 'Property does not exist');
            
            let timestamp = get_block_timestamp();
            
            self.verified_properties.entry(token_id).write(true);
            self.verification_timestamps.entry(token_id).write(timestamp);
            self.verifiers.entry(token_id).write(verifier);
            
            self.emit(PropertyVerified {
                token_id,
                verifier,
                timestamp,
            });
        }

        fn transfer_property(ref self: ContractState, token_id: u256, to: ContractAddress) {
            let caller = get_caller_address();
            let current_owner = self.property_owners.entry(token_id).read();
            
            assert(caller == current_owner, 'Not property owner');
            assert(to.is_non_zero(), 'Invalid recipient');
            
            let timestamp = get_block_timestamp();
            
            // Update ownership
            self.property_owners.entry(token_id).write(to);
            
            // Add to history
            let history_count = self.property_history_count.entry(token_id).read();
            self.property_history.entry((token_id, history_count)).write(to);
            self.property_history_count.entry(token_id).write(history_count + 1);
            
            self.emit(PropertyTransferred {
                token_id,
                from: current_owner,
                to,
                timestamp,
            });
        }

        fn update_property_price(ref self: ContractState, token_id: u256, new_price: u256) {
            let caller = get_caller_address();
            let owner = self.property_owners.entry(token_id).read();
            
            assert(caller == owner, 'Not property owner');
            
            let old_price = self.property_prices.entry(token_id).read();
            self.property_prices.entry(token_id).write(new_price);
            
            self.emit(PriceUpdated {
                token_id,
                old_price,
                new_price,
                timestamp: get_block_timestamp(),
            });
        }

        fn update_metadata(ref self: ContractState, token_id: u256, new_metadata_uri: ByteArray) {
            let caller = get_caller_address();
            let owner = self.property_owners.entry(token_id).read();
            
            assert(caller == owner, 'Not property owner');
            
            self.property_metadata.entry(token_id).write(new_metadata_uri.clone());
            
            self.emit(MetadataUpdated {
                token_id,
                new_metadata_uri,
                timestamp: get_block_timestamp(),
            });
        }

        fn get_property_owner(self: @ContractState, token_id: u256) -> ContractAddress {
            self.property_owners.entry(token_id).read()
        }

        fn get_property_metadata(self: @ContractState, token_id: u256) -> ByteArray {
            self.property_metadata.entry(token_id).read()
        }

        fn get_property_price(self: @ContractState, token_id: u256) -> u256 {
            self.property_prices.entry(token_id).read()
        }

        fn is_verified(self: @ContractState, token_id: u256) -> bool {
            self.verified_properties.entry(token_id).read()
        }

        fn get_verification_timestamp(self: @ContractState, token_id: u256) -> u64 {
            self.verification_timestamps.entry(token_id).read()
        }

        fn get_property_history(self: @ContractState, token_id: u256) -> Array<ContractAddress> {
            let count = self.property_history_count.entry(token_id).read();
            let mut history = ArrayTrait::new();
            let mut i: u256 = 0;
            
            loop {
                if i >= count {
                    break;
                }
                let owner = self.property_history.entry((token_id, i)).read();
                history.append(owner);
                i += 1;
            };
            
            history
        }

        fn total_properties(self: @ContractState) -> u256 {
            self.total_supply.read()
        }
    }

    // Admin functions
    #[generate_trait]
    impl AdminImpl of AdminTrait {
        fn authorize_verifier(ref self: ContractState, verifier: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Only admin');
            
            self.authorized_verifiers.entry(verifier).write(true);
            
            self.emit(VerifierAuthorized {
                verifier,
                timestamp: get_block_timestamp(),
            });
        }

        fn revoke_verifier(ref self: ContractState, verifier: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Only admin');
            
            self.authorized_verifiers.entry(verifier).write(false);
            
            self.emit(VerifierRevoked {
                verifier,
                timestamp: get_block_timestamp(),
            });
        }
    }
}
