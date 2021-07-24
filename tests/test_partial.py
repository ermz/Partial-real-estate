import pytest
from brownie import Wei, ZERO_ADDRESS, accounts, partial
from eth_hash.auto import keccak

@pytest.fixture
def _partial():
    _partial = partial.deploy({"from": accounts[0]})
    return _partial

@pytest.fixture
def _partial_management():
    _partial_management = partial.deploy({"from":accounts[0]})
    _partial_management.management_access({'from':accounts[7], 'value':'1 ether'})
    return _partial_management

def test_management_access(_partial):
    assert _partial.validate_management(accounts[3]) == False
    _partial.management_access({'from':accounts[3], 'value':'1 ether'})
    assert _partial.validate_management(accounts[3]) == True

def test_approve_broker_and_agent(_partial_management):
    assert _partial_management.validate_broker(accounts[2], accounts[7]) == False
    _partial_management.approve_broker(accounts[2], {'from': accounts[7]})
    assert _partial_management.validate_broker(accounts[2], accounts[7]) == True
    assert _partial_management.validate_agent(accounts[3], accounts[7]) == False
    _partial_management.approve_agent(accounts[3], {'from': accounts[2], 'value': '1 ether'})
    assert _partial_management.validate_agent(accounts[3], accounts[7]) == True

def test_add_listing(_partial):
    listing_password = "Super Secret Password"
    _partial.add_listing(listing_password, "505 Mott Street", 3000, {'from': accounts[2], 'value': '2 ether'})
    new_keccak = keccak(b'Super Secret Password')
    assert _partial.view_exclusive_owner(new_keccak) == accounts[2]
    # Quick set-up of adding a management company and a partner broker
    _partial.management_access({'from': accounts[4], 'value': '1 ether'})
    _partial.approve_broker(accounts[5], {'from': accounts[4]})
    _partial.approve_exclusive(new_keccak, accounts[5])
    exclusive_struct = _partial.view_exclusive(new_keccak, {'from': accounts[5]})
    assert _partial.view_exclusive_pass_struct(new_keccak) == exclusive_struct
    assert _partial.view_approve_exclusive(new_keccak, accounts[5]) == True

