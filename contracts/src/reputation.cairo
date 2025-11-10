#[starknet::contract]
mod Reputation {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess
    };
    use super::super::interfaces::IReputation;

    #[storage]
    struct Storage {
        // Agent data
        agent_metadata: Map<ContractAddress, ByteArray>,
        agent_verified: Map<ContractAddress, bool>,
        agent_registration_time: Map<ContractAddress, u64>,
        
        // Reputation scores
        agent_total_score: Map<ContractAddress, u256>,
        agent_review_count: Map<ContractAddress, u256>,
        agent_fraud_reports: Map<ContractAddress, u256>,
        
        // Review tracking
        review_exists: Map<(ContractAddress, ContractAddress, u256), bool>, // (agent, reviewer, property) -> bool
        review_ratings: Map<u256, u8>, // review_id -> rating
        review_hashes: Map<u256, felt252>, // review_id -> content hash
        next_review_id: u256,
        
        // Fraud reports
        fraud_report_count: Map<ContractAddress, u256>,
        fraud_evidence: Map<(ContractAddress, u256), felt252>, // (agent, report_index) -> evidence_hash
        
        // Admin
        admin: ContractAddress,
        authorized_verifiers: Map<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AgentRegistered: AgentRegistered,
        AgentVerified: AgentVerified,
        VerificationRevoked: VerificationRevoked,
        ReviewAdded: ReviewAdded,
        FraudReported: FraudReported,
    }

    #[derive(Drop, starknet::Event)]
    struct AgentRegistered {
        #[key]
        agent: ContractAddress,
        metadata_uri: ByteArray,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct AgentVerified {
        #[key]
        agent: ContractAddress,
        #[key]
        verifier: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct VerificationRevoked {
        #[key]
        agent: ContractAddress,
        #[key]
        revoker: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct ReviewAdded {
        #[key]
        agent: ContractAddress,
        #[key]
        reviewer: ContractAddress,
        #[key]
        property_token_id: u256,
        rating: u8,
        review_id: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct FraudReported {
        #[key]
        agent: ContractAddress,
        #[key]
        reporter: ContractAddress,
        #[key]
        property_token_id: u256,
        evidence_hash: felt252,
        timestamp: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
        self.next_review_id.write(1);
        self.authorized_verifiers.entry(admin).write(true);
    }

    #[abi(embed_v0)]
    impl ReputationImpl of IReputation<ContractState> {
        fn register_agent(ref self: ContractState, agent: ContractAddress, metadata_uri: ByteArray) {
            let caller = get_caller_address();
            assert(caller == agent, 'Can only register self');
            
            let registration_time = self.agent_registration_time.entry(agent).read();
            assert(registration_time == 0, 'Agent already registered');
            
            let timestamp = get_block_timestamp();
            
            self.agent_metadata.entry(agent).write(metadata_uri.clone());
            self.agent_registration_time.entry(agent).write(timestamp);
            self.agent_total_score.entry(agent).write(0);
            self.agent_review_count.entry(agent).write(0);
            self.agent_fraud_reports.entry(agent).write(0);
            
            self.emit(AgentRegistered {
                agent,
                metadata_uri,
                timestamp,
            });
        }

        fn add_review(
            ref self: ContractState,
            agent: ContractAddress,
            reviewer: ContractAddress,
            rating: u8,
            property_token_id: u256,
            review_hash: felt252
        ) {
            let caller = get_caller_address();
            assert(caller == reviewer, 'Not the reviewer');
            assert(rating >= 1 && rating <= 5, 'Rating must be 1-5');
            
            // Check if agent is registered
            let registration_time = self.agent_registration_time.entry(agent).read();
            assert(registration_time > 0, 'Agent not registered');
            
            // Prevent duplicate reviews for same property
            let review_key = (agent, reviewer, property_token_id);
            assert(!self.review_exists.entry(review_key).read(), 'Review already exists');
            
            let review_id = self.next_review_id.read();
            let timestamp = get_block_timestamp();
            
            // Store review
            self.review_exists.entry(review_key).write(true);
            self.review_ratings.entry(review_id).write(rating);
            self.review_hashes.entry(review_id).write(review_hash);
            
            // Update agent score
            let current_total = self.agent_total_score.entry(agent).read();
            let current_count = self.agent_review_count.entry(agent).read();
            
            self.agent_total_score.entry(agent).write(current_total + rating.into());
            self.agent_review_count.entry(agent).write(current_count + 1);
            
            // Update counter
            self.next_review_id.write(review_id + 1);
            
            self.emit(ReviewAdded {
                agent,
                reviewer,
                property_token_id,
                rating,
                review_id,
                timestamp,
            });
        }

        fn report_fraud(
            ref self: ContractState,
            agent: ContractAddress,
            property_token_id: u256,
            evidence_hash: felt252
        ) {
            let caller = get_caller_address();
            let timestamp = get_block_timestamp();
            
            // Check if agent is registered
            let registration_time = self.agent_registration_time.entry(agent).read();
            assert(registration_time > 0, 'Agent not registered');
            
            // Increment fraud reports
            let current_reports = self.agent_fraud_reports.entry(agent).read();
            self.agent_fraud_reports.entry(agent).write(current_reports + 1);
            
            // Store evidence
            self.fraud_evidence.entry((agent, current_reports)).write(evidence_hash);
            
            self.emit(FraudReported {
                agent,
                reporter: caller,
                property_token_id,
                evidence_hash,
                timestamp,
            });
        }

        fn verify_agent(ref self: ContractState, agent: ContractAddress) {
            let caller = get_caller_address();
            assert(self.authorized_verifiers.entry(caller).read(), 'Not authorized verifier');
            
            // Check if agent is registered
            let registration_time = self.agent_registration_time.entry(agent).read();
            assert(registration_time > 0, 'Agent not registered');
            
            self.agent_verified.entry(agent).write(true);
            
            self.emit(AgentVerified {
                agent,
                verifier: caller,
                timestamp: get_block_timestamp(),
            });
        }

        fn revoke_verification(ref self: ContractState, agent: ContractAddress) {
            let caller = get_caller_address();
            assert(self.authorized_verifiers.entry(caller).read(), 'Not authorized verifier');
            
            self.agent_verified.entry(agent).write(false);
            
            self.emit(VerificationRevoked {
                agent,
                revoker: caller,
                timestamp: get_block_timestamp(),
            });
        }

        fn get_agent_score(self: @ContractState, agent: ContractAddress) -> u256 {
            let total = self.agent_total_score.entry(agent).read();
            let count = self.agent_review_count.entry(agent).read();
            
            if count == 0 {
                return 0;
            }
            
            // Return average score * 100 for precision (e.g., 450 = 4.50 stars)
            (total * 100) / count
        }

        fn get_agent_review_count(self: @ContractState, agent: ContractAddress) -> u256 {
            self.agent_review_count.entry(agent).read()
        }

        fn is_agent_verified(self: @ContractState, agent: ContractAddress) -> bool {
            self.agent_verified.entry(agent).read()
        }

        fn get_fraud_reports(self: @ContractState, agent: ContractAddress) -> u256 {
            self.agent_fraud_reports.entry(agent).read()
        }

        fn get_agent_metadata(self: @ContractState, agent: ContractAddress) -> ByteArray {
            self.agent_metadata.entry(agent).read()
        }
    }

    // Admin functions
    #[generate_trait]
    impl AdminImpl of AdminTrait {
        fn authorize_verifier(ref self: ContractState, verifier: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Only admin');
            self.authorized_verifiers.entry(verifier).write(true);
        }

        fn revoke_verifier_authorization(ref self: ContractState, verifier: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Only admin');
            self.authorized_verifiers.entry(verifier).write(false);
        }
    }
}
