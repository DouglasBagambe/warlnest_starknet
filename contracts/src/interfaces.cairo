use starknet::ContractAddress;

#[starknet::interface]
pub trait IPropertyRegistry<TContractState> {
    // Property Management
    fn mint_property(
        ref self: TContractState,
        property_id: felt252,
        owner: ContractAddress,
        metadata_uri: ByteArray,
        price: u256,
        property_type: u8,
        location_hash: felt252
    ) -> u256;
    
    fn verify_property(ref self: TContractState, token_id: u256, verifier: ContractAddress);
    fn transfer_property(ref self: TContractState, token_id: u256, to: ContractAddress);
    fn update_property_price(ref self: TContractState, token_id: u256, new_price: u256);
    fn update_metadata(ref self: TContractState, token_id: u256, new_metadata_uri: ByteArray);
    
    // Getters
    fn get_property_owner(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_property_metadata(self: @TContractState, token_id: u256) -> ByteArray;
    fn get_property_price(self: @TContractState, token_id: u256) -> u256;
    fn is_verified(self: @TContractState, token_id: u256) -> bool;
    fn get_verification_timestamp(self: @TContractState, token_id: u256) -> u64;
    fn get_property_history(self: @TContractState, token_id: u256) -> Array<ContractAddress>;
    fn total_properties(self: @TContractState) -> u256;
}

#[starknet::interface]
pub trait IEscrow<TContractState> {
    // Escrow Management
    fn create_escrow(
        ref self: TContractState,
        property_token_id: u256,
        buyer: ContractAddress,
        amount: u256,
        escrow_type: u8, // 0: booking fee, 1: deposit, 2: full payment
        release_conditions: ByteArray
    ) -> u256;
    
    fn deposit_funds(ref self: TContractState, escrow_id: u256);
    fn release_funds(ref self: TContractState, escrow_id: u256);
    fn refund_escrow(ref self: TContractState, escrow_id: u256);
    fn dispute_escrow(ref self: TContractState, escrow_id: u256, reason: ByteArray);
    fn resolve_dispute(ref self: TContractState, escrow_id: u256, release_to_seller: bool);
    
    // Getters
    fn get_escrow_status(self: @TContractState, escrow_id: u256) -> u8;
    fn get_escrow_amount(self: @TContractState, escrow_id: u256) -> u256;
    fn get_escrow_parties(self: @TContractState, escrow_id: u256) -> (ContractAddress, ContractAddress);
    fn is_disputed(self: @TContractState, escrow_id: u256) -> bool;
}

#[starknet::interface]
pub trait IReputation<TContractState> {
    // Reputation Management
    fn register_agent(ref self: TContractState, agent: ContractAddress, metadata_uri: ByteArray);
    fn add_review(
        ref self: TContractState,
        agent: ContractAddress,
        reviewer: ContractAddress,
        rating: u8, // 1-5
        property_token_id: u256,
        review_hash: felt252
    );
    
    fn report_fraud(
        ref self: TContractState,
        agent: ContractAddress,
        property_token_id: u256,
        evidence_hash: felt252
    );
    
    fn verify_agent(ref self: TContractState, agent: ContractAddress);
    fn revoke_verification(ref self: TContractState, agent: ContractAddress);
    
    // Getters
    fn get_agent_score(self: @TContractState, agent: ContractAddress) -> u256;
    fn get_agent_review_count(self: @TContractState, agent: ContractAddress) -> u256;
    fn is_agent_verified(self: @TContractState, agent: ContractAddress) -> bool;
    fn get_fraud_reports(self: @TContractState, agent: ContractAddress) -> u256;
    fn get_agent_metadata(self: @TContractState, agent: ContractAddress) -> ByteArray;
}
