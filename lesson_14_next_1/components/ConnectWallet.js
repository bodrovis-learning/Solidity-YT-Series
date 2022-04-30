import { NetworkErrorMessage } from "./NetworkErrorMessage"

export function ConnectWallet({ connectWallet, networkError, dismiss }) {
  return (
    <>
      <div>
        {networkError && (
          <NetworkErrorMessage 
            message={networkError} 
            dismiss={dismiss} 
          />
        )}
      </div>

      <p>Please connect your account...</p>
      <button type="button" onClick={connectWallet}>
        Connect Wallet
      </button>
    </>
  )
}