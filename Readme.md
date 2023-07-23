## Live Demo
Video: https://youtu.be/Uj4aNN3DN8Y

URL: https://e2dd-2401-4900-1f3f-2483-b911-74cf-194-a97d.ngrok-free.app/portfolio

![image](https://github.com/placeholder-defi/placeholder-defi/assets/114165664/cf630ffc-1b81-494b-983b-33de84e64aaa)

## Safe-Globle
As part of account The Safe{Core} Account Abstraction 

Dynmic we are creating wallet from contract for each vault

https://github.com/placeholder-defi/placeholder-defi/blob/1a7033afe61c835760ab70147b55d09ebff240aa/contract/contracts/Factory.sol#L40

![Screenshot 2023-07-23 at 3 59 25 PM](https://github.com/placeholder-defi/placeholder-defi/assets/114165664/b411b0f1-b078-4be8-a28a-8610dd13c26f)


## Walletconnect

we have us WalletConnect
https://github.com/placeholder-defi/placeholder-defi/blob/1a7033afe61c835760ab70147b55d09ebff240aa/app/components/ui/page.jsx#L3

https://github.com/placeholder-defi/placeholder-defi/blob/1a7033afe61c835760ab70147b55d09ebff240aa/app/components/ui/page.jsx#L47


## ChainLink

Vault asset we are using chainlink price feed.
Price oracel : https://github.com/placeholder-defi/placeholder-defi/blob/main/contract/contracts/oracle/PriceOracle.sol (PriceOracle - 0xa952E2bA9a7f73F8B0c7FE9Fda64227b6Bed1117
)
https://github.com/placeholder-defi/placeholder-defi/blob/65bd81592599c5ffbd6311f21e141e763336f962/contract/contracts/ShortTermFund.sol#L290

#### Vault asset manager  trade is in progress
In the case where a trade is in progress the investor can not deposit but can program its deposit through  ChainLink keeper which will deposit for the user once the trade will be closed.

Moreover the users are able to program an automatic withdraw with ChainLink keeper .
https://github.com/placeholder-defi/placeholder-defi/blob/65bd81592599c5ffbd6311f21e141e763336f962/contract/contracts/ShortTermFund.sol#L15
https://github.com/placeholder-defi/placeholder-defi/blob/1a7033afe61c835760ab70147b55d09ebff240aa/contract/contracts/VelvetShortTermFund.sol#L206


### Arbitrum
https://arbiscan.io/tx/0x5616b6608e95a0ab1243ed4a8b02b173666bae9535db3ceccc54b2158dd7210a

### Polygon
https://polygonscan.com/address/0x55975a9435d62ddc912f2816435d7617fd87647c


### Gonsis
Gonsis chain we have deploy all contract : https://gnosisscan.io/address/0xB33d0d4CDF4F0Accb604Fd41a689E9156949aE70

PriceOracle - 0xa952E2bA9a7f73F8B0c7FE9Fda64227b6Bed1117
SafeModule - 0xB5229591B13B044c6c34C02628036104FC016421
Factory - 0xB33d0d4CDF4F0Accb604Fd41a689E9156949aE70
FundContract - 0xB33d0d4CDF4F0Accb604Fd41a689E9156949aE70
