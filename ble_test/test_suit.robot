*** Settings ***
Suite Setup                   Setup
Suite Teardown                Teardown
Test Setup                    Reset Emulation
Test Teardown                 Test Teardown
Resource                      ${RENODEKEYWORDS}

*** Variables ***
${UART}                       sysbus.uart0
${URI}                        @https://dl.antmicro.com/projects/renode

${STANDARD}=  SEPARATOR=
...  """                                     ${\n}
...  using "platforms/cpus/nrf52840.repl"    ${\n}
...  """


*** Keywords ***
Create Machine
    [Arguments]              ${platform}  ${elf}

    Execute Command          mach create
    Execute Command          machine LoadPlatformDescriptionFromString ${platform}

    Execute Command          sysbus LoadELF ${URI}/${elf}

Run ZephyrRTOS Shell
    [Arguments]               ${platform}  ${elf}

    Create Machine            ${platform}  ${elf}
    Create Terminal Tester    ${UART}

    Execute Command           showAnalyzer ${UART}

    Start Emulation
    Wait For Prompt On Uart   uart:~$
    Write Line To Uart        demo ping
    Wait For Line On Uart     pong

*** Test Cases ***
Should Run Bluetooth sample
    Execute Command           emulation CreateBLEMedium "wireless"

    Execute Command           mach add "central"
    Execute Command           machine LoadPlatformDescription @platforms/cpus/nrf52840.repl
    Execute Command           sysbus LoadELF @C:/Users/ltmin/zypherbin/zephyr-ble-central_hr.elf
    Execute Command           connector Connect sysbus.radio wireless

    Execute Command           showAnalyzer ${UART}
    ${cen_uart}=  Create Terminal Tester   ${UART}   machine=central

    Execute Command           mach add "peripheral"
    Execute Command           mach set "peripheral"
    Execute Command           machine LoadPlatformDescription @platforms/cpus/nrf52840.repl
    Execute Command           sysbus LoadELF @C:/Users/ltmin/zypherbin/zephyr-ble-peripheral_hr.elf
    Execute Command           connector Connect sysbus.radio wireless

    Execute Command           showAnalyzer ${UART}
    ${per_uart}=  Create Terminal Tester   ${UART}   machine=peripheral

    Execute Command           emulation SetGlobalQuantum "0.00001"

    Start Emulation

    Wait For Line On Uart     Booting Zephyr                    testerId=${cen_uart}
    Wait For Line On Uart     Booting Zephyr                    testerId=${per_uart}

    Wait For Line On Uart     Bluetooth initialized             testerId=${cen_uart}
    Wait For Line On Uart     Bluetooth initialized             testerId=${per_uart}

    Wait For Line On Uart     Scanning successfully started     testerId=${cen_uart}
    Wait For Line On Uart     Advertising successfully started  testerId=${per_uart}

    Wait For Line On Uart     Connected: C0:00:AA:BB:CC:DD      testerId=${cen_uart}
    Wait For Line On Uart     Connected                         testerId=${per_uart}

    Wait For Line On Uart     HRS notifications enabled         testerId=${per_uart}

    Wait For Line On Uart     [SUBSCRIBED]                      testerId=${cen_uart}
    Wait For Line On Uart     [NOTIFICATION]                    testerId=${cen_uart}
