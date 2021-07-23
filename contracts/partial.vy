# @version ^0.2.0

# Treat real estate papers as an NFT
# This NFT gives ownership of a home to a specific address
# Key features
# 1. Can have multiple addresses own percentages of a home
# 2. Helps broker the renting of a home aswell, allowing addresses to be tied to the NFT. (Leasee, Guarantor, etc.)
# 3. Using an off-line Oracle, if original owner of address passes away. The NFT maybe be sent to a separate address that was place as an inheritor
# 4. Again the NFT can have multiple ownership of a home by percentages
# 5. In order to transfer the NFT to someone else, They will need to have 51% in order to perform such a function (assuming there is more than one owner)

# Real problem, with real solutions in Real Estate
# Getting access to keys is a pain in the ass
# Pros
# 1. You don't have to bother supers
# 2. No looking around for keys
# 3. No need to annoy residents, when going to preview a unit
# 4. Livetime tracking of who has access to what, could have an off-chain database that keeps tabs of who went where
# 5. Easier for Brokers to keep track of their employees (I don't like this part, but also brokers are liable for their agents so... Necessiry evil)

# Cons
# 1. Adoption of technology
# 2. Realtors would have to stake tokens/stablecoins to have privilege to enter buildings, depending on their broker
# 3. 

# Brokers address and management company address used to see if they have a partnership
# It will always give False if it hasn't been setup beforehand to true
# Every management company has to individually give access to brokers
brokerToManagement: HashMap[address, HashMap[address, bool]]

# Same idea brokers need to include their agents under his address
# This will grant agents access to whatever the he has access too
# Having a HashMap broker <-> agent works because you CAN'T be liscenced under multiple brokers
agentToBroker: HashMap[address, address]

# Exclusive listing only meant for a finite number of broker/agents
# Could potentially be time-based aswell
# Or could also only be used once, before permission needs to be granted as well
# checks if Real Estate id has been given to broker, will return a boolean
exclusiveToBroker: HashMap[String[50] ,HashMap[address, bool]]

# Will be used to determina wether or not the management company works with us and
# if a broker can subscribe to them
managementList: HashMap[address, bool]

brokerList: HashMap[address, bool]

# The creator will only work with management companies who want to place their listings available for brokers
# They will need to pay a fraction of ETH to include a particular broker to their partnership
# On the other hand brokers will also have to pay to enter in partnership with management company
# Agents will also have to pay a small fee to be under the brokers system
manager: address

@external
def __init__():
    self.manager = msg.sender

# This will verify if that management company works with our brokerage
# Ideally this can be setup with  super/management offices/lockboxes that can scan. Anything that will add trust to the process
# A pro is that everyone has their phone on them
# Will help reduce the number of crooks that work in person or online
# We could have people have special wallets just for real estate work. One that they can share and prove that they do work with certain companies
# Someone from home could check this with the agents address and can trust them better
# Better than a random business card, headshot picture or whathave your
# Will take trust out of the process, biggest problem is adoption
# That being said popular/smart firms will adopt in order to seem hip and trustworthy
# @external
# @view
# def brokerList(broker: address, management: address) -> bool:
#     return self.inPartnership(broker, management)

@external
@payable
def managment_access() -> bool:
    assert msg.value == 1, "You must pay 1 ether in order for your company to be included"
    assert self.managementList[msg.sender] == False

    self.managementList[msg.sender] = True
    return True

@external
def approve_broker(broker: address) -> address:
    assert self.managementList[msg.sender] == True, "You must be a part of Partial in order to add brokers"
    assert broker != ZERO_ADDRESS
    assert self.brokerToManagement[broker][msg.sender] == False, "This broker is already in a partnership with your management company"

    self.brokerList[broker] = True
    self.brokerToManagement[broker][msg.sender] = True
    return broker

@external
@payable
def approve_agent(agent: address) -> address:
    assert msg.value == 1, "You must pay 1 ether in order for your company to be included"
    assert self.brokerList[msg.sender] == True, "You don't work with any of our partnered management companies"
    assert self.agentToBroker[agent] != msg.sender, "This agent is already partnered with you"

    self.agentToBroker[agent] = msg.sender
    return agent

# From the POV of a super/management company/ whoever to give access to keys/whatever for entry
@external
@view
def validate_broker(broker: address, management: address) -> bool:
    return self.brokerToManagement[broker][management]

# From similar toe validate_broker but for agents
@external
@view
def validate_agent(agent: address, management: address) -> bool:
    broker_addr: address = self.agentToBroker[agent]
    return self.brokerToManagement[broker_addr][management]

ownerExclusiveListing: HashMap[uint256, address]

struct ExclusiveListing:
    streetName: String[100]
    price: uint256

exclusivePassToStruct: HashMap[uint256, ExclusiveListing]

approveExclusiveListing: HashMap[uint256, HashMap[address, bool]]

@external
def add_listing(_listing_id: String[32], _streetName: String[100], _price: uint256) -> uint256:
    listing_password: uint256 = convert(keccak256(_listing_id), uint256)
    # Will have to re-do this part. There's too much querying for something so simple
    assert self.ownerExclusiveListing[listing_password] != msg.sender
    self.ownerExclusiveListing[listing_password] = msg.sender
    self.exclusivePassToStruct[listing_password] = ExclusiveListing({
        streetName: _streetName,
        price: _price
    })
    return listing_password

# Specifically for Individual trying to give access to Real Estate Brokers/Agents
# management companies will have a separate process for real estate brokers/agents
@external
def approve_exclusive(listing_password: uint256, broker: address) -> address:
    assert self.brokerList[broker] == True, "This broker is not partnered with any of our management companies, be wary"
    assert self.approveExclusiveListing[listing_password][broker] == False, "This broker is already on the Exclusive listing"
    return msg.sender

# The idea now is that the management company gives the Broker the listing password so he can access the information
# will have a struct that details the exclusive listing only to those specific brokers and grant them access
@external
@view
def view_exclusive(listing_password: uint256) -> ExclusiveListing:
    assert self.brokerList[msg.sender] == True, "You are not partnered with any of our management companies or independent landlords"
    return self.exclusivePassToStruct[listing_password]

    