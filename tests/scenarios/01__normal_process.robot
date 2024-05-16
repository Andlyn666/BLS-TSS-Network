*** Settings ***
Documentation       Node Registration Scenarios

Library             src/environment/contract.py
Library             src/environment/log.py
Resource            src/common.resource
Resource            src/contract.resource
Resource            src/node.resource

*** Keywords ***

Normal Process
    [Documentation]
    ...    This test case is to test the normal node registration process.
    Set Enviorment And Deploy Contract
    ${node1} =    Stake And Run Node    1
    ${node2} =    Stake And Run Node    2
    ${node3} =    Stake And Run Node    3
    ${log_phase_1} =    All Nodes Have Keyword    Waiting for Phase 1 to start    ${NODE_PROCESS_LIST}
    Mine Blocks    9
    ${log_phase_2} =    All Nodes Have Keyword    Waiting for Phase 2 to start    ${NODE_PROCESS_LIST}
    Mine Blocks    9
    ${log_group} =    All Nodes Have Keyword    Group index:0 epoch:1 is available    ${NODE_PROCESS_LIST}
    ${result} =    Get Group    0
    Group Node Number Should Be    0    3
    Mine Blocks    20
    Sleep    2s
    Deploy User Contract
    Request Randomness
    ${log_received_randomness_task} =    All Nodes Have Keyword    received new randomness task    ${NODE_PROCESS_LIST}
    Sleep    5s
    Mine Blocks    6
    ${result} =    Have Node Got Keyword    fulfill randomness successfully    ${NODE_PROCESS_LIST}
    Sleep    5s
    #Check Randomness
    Teardown Scenario Testing Environment

Test Rebalance
    Sleep    3s
    Set Global Variable    $BLOCK_TIME    1
    Set Enviorment And Deploy Contract
    Sleep    3s
    
    ${node1} =    Stake And Run Node    1
    ${node2} =    Stake And Run Node    2
    ${node3} =    Stake And Run Node    3
    ${node4} =    Stake And Run Node    4
    ${node5} =    Stake And Run Node    5

    ${result} =    All Nodes Have Keyword    Transaction successful(node_register)    ${NODE_PROCESS_LIST}
    Should Be True    ${result}
    ${get_share} =    All Nodes Have Keyword    Calling contract view get_shares    ${NODE_PROCESS_LIST}
    ${group_result} =    Have Node Got Keyword    Group index:0 epoch:3 is available    ${NODE_PROCESS_LIST}    
    Group Node Number Should Be    0    5

    ${node6} =    Stake And Run Node    6
    ${result} =        Get Keyword From Node Log    6    Transaction successful(node_register)
    ${get_share} =    All Nodes Have Keyword    Calling contract view get_shares    ${NODE_PROCESS_LIST}
    ${group_result} =    Get Keyword From Node Log    6    is available
    ${node1} =    Stake And Run Node    7
    ${node2} =    Stake And Run Node    8
    ${node3} =    Stake And Run Node    9
    ${group_result} =    Get Keyword From Node Log    9    is available

    Get Group    0
    Get Group    1
    Get Group    2
    
    ${start_block} =    Get Latest Block Number
    Sleep    5s

    ${private_key} =    Get Private Key By Index    7
    Cast Send    ${CONTRACT_ADDRESSES['ControllerProxy']}    "nodeQuit()"   ${private_key}    ${EMPTY}
    Sleep    2s
    ${private_key} =    Get Private Key By Index    2
    Cast Send    ${CONTRACT_ADDRESSES['ControllerProxy']}    "nodeQuit()"   ${private_key}    ${EMPTY}
    Sleep    2s
    ${private_key} =    Get Private Key By Index    6
    Cast Send    ${CONTRACT_ADDRESSES['ControllerProxy']}    "nodeQuit()"   ${private_key}    ${EMPTY}
    Sleep    2s

    ${private_key} =    Get Private Key By Index    8
    Cast Send    ${CONTRACT_ADDRESSES['ControllerProxy']}    "nodeQuit()"   ${private_key}    ${EMPTY}

    Sleep    20s
    ${event} =    get_events    ${CONTROLLER_CONTRACT}    DkgTask    ${start_block}
    ${event} =    get_events    ${CONTROLLER_CONTRACT}    TestEvent    ${start_block}
    ${event} =    get_events    ${CONTROLLER_CONTRACT}    NodeQuit    ${start_block}

Test Rebalance 2
    Sleep    3s
    Set Global Variable    $BLOCK_TIME    1
    Set Enviorment And Deploy Contract
    Sleep    3s
    
    ${node1} =    Stake And Run Node    1
    ${node2} =    Stake And Run Node    2
    ${node3} =    Stake And Run Node    3
    ${node4} =    Stake And Run Node    4
    ${node5} =    Stake And Run Node    5

    ${result} =    All Nodes Have Keyword    Transaction successful(node_register)    ${NODE_PROCESS_LIST}
    Should Be True    ${result}
    ${get_share} =    All Nodes Have Keyword    Calling contract view get_shares    ${NODE_PROCESS_LIST}
    ${group_result} =    Have Node Got Keyword    Group index:0 epoch:3 is available    ${NODE_PROCESS_LIST}    
    Group Node Number Should Be    0    5

    ${node6} =    Stake And Run Node    6
    ${result} =        Get Keyword From Node Log    6    Transaction successful(node_register)
    ${get_share} =    All Nodes Have Keyword    Calling contract view get_shares    ${NODE_PROCESS_LIST}
    ${group_result} =    Get Keyword From Node Log    6    is available
    ${node1} =    Stake And Run Node    7
    ${node2} =    Stake And Run Node    8
    ${node3} =    Stake And Run Node    9
    ${group_result} =    Get Keyword From Node Log    9    is available

    Get Group    0
    Get Group    1
    Get Group    2
    
    ${start_block} =    Get Latest Block Number
    Sleep    5s


    ${private_key} =    Get Private Key By Index    1
    Cast Send    ${CONTRACT_ADDRESSES['ControllerProxy']}    "nodeQuit()"   ${private_key}    ${EMPTY}
    Sleep    2s

    ${private_key} =    Get Private Key By Index    6
    Cast Send    ${CONTRACT_ADDRESSES['ControllerProxy']}    "nodeQuit()"   ${private_key}    ${EMPTY}
    
    Sleep    2s
    ${private_key} =    Get Private Key By Index    7
    Cast Send    ${CONTRACT_ADDRESSES['ControllerProxy']}    "nodeQuit()"   ${private_key}    ${EMPTY}
    

    Sleep    20s
    ${event} =    get_events    ${CONTROLLER_CONTRACT}    DkgTask    ${start_block}
    ${event} =    get_events    ${CONTROLLER_CONTRACT}    TestEvent    ${start_block}
    ${event} =    get_events    ${CONTROLLER_CONTRACT}    NodeQuit    ${start_block}
    
*** Test Cases ***
Run Normal Process
    [Tags]    l1
    Repeat Keyword    1    Normal Process
    Repeat Keyword    0    Test Rebalance
    Repeat Keyword    0    Test Rebalance 2